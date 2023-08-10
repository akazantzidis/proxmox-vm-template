#!/bin/bash
set -x
envfile=${1}
# Check if we passed any environment variables file

if [[ -z ${envfile} ]];then
  echo "No required variables file passed.Exiting"
  exit 1
fi

# Check if libguestfs-tools is installed - exit if it isn't.
REQUIRED_PKG="libguestfs-tools"
if [[ -f /etc/debian_version ]];then
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${REQUIRED_PKG}|grep "install ok installed")
    echo "Checking for ${REQUIRED_PKG}: ${PKG_OK}"
    if [ "" = "${PKG_OK}" ]; then
        echo "No ${REQUIRED_PKG}. Please run apt-get install ${REQUIRED_PKG}."
        exit
    fi
elif [[ "$(grep -Ei 'fedora|redhat' /etc/*release)" ]];then
    PKG_OK=$(rpm -qa | grep ${REQUIRED_PKG})
    if [ "" = "${PKG_OK}" ]; then
        echo "No ${REQUIRED_PKG}. Please run yum/dnf install ${REQUIRED_PKG}."
        exit 1
    fi
fi

# Init globals
CLEANUP=yes
HYPERVISOR=false
SETX11=yes
LOCALLANG=en_us.UTF-8
X11LAYOUT=us
X11MODEL=pc105
VIRTPKG=
SSH_PASS_AUTH=no
MEM=1024
BALLOON=0
CORES=1
BIOS=ovmf
MACHINE=q35
NET_BRIDGE=vmbr0
AGENT_ENABLE=1
FSTRIM=1
OS_TYPE=l26
TZ=UTC
ZFS=false
SSH_PASS_AUTH=no
SSHKEY=""
VLAN=""
DISK_SIZE=""

# Source input variables files
if [[ ${envfile} ]];then
  source ${envfile}
  if [[ $? != 0 ]];then
      echo "Cannot import variables file"
      exit 1
  fi
fi

if [[ -z ${WORK_DIR} ]];then
    export WORK_DIR=/tmp
fi

# Helper variables and transformations
SRC_IMG=${SRC_URL##*/}
IMG_NAME="${SRC_IMG/.*/.qcow2}"
echo ${IMG_NAME}
read -p "Enter a VM Template Name [$TEMPL_NAME_DEFAULT]: " TEMPL_NAME
TEMPL_NAME=${TEMPL_NAME:-$TEMPL_NAME_DEFAULT}
read -p "Enter a VM ID for $TEMPL_NAME_DEFAULT [$VMID_DEFAULT]: " VMID
VMID=${VMID:-$VMID_DEFAULT}
read -p "Enter a Cloud-Init Username for $TEMPL_NAME_DEFAULT [$CLOUD_USER_DEFAULT]: " CLOUD_USER
CLOUD_USER=${CLOUD_USER:-$CLOUD_USER_DEFAULT}
GENPASS=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
CLOUD_PASSWORD_DEFAULT=$GENPASS
read -p "Enter a Cloud-Init Password for $TEMPL_NAME_DEFAULT [$CLOUD_PASSWORD_DEFAULT]: " CLOUD_PASSWORD
CLOUD_PASSWORD=${CLOUD_PASSWORD:-$CLOUD_PASSWORD_DEFAULT}

# Last check for all needed input are inplace
for i in '$SRC_URL' '$TEMPL_NAME_DEFAULT' '$VMID_DEFAULT' '$CLOUD_USER_DEFAULT';do
    if [[ $(eval echo ${i}) == '' ]];then
      echo "Variable ${i} is not set.Exiting"
      exit 1
    fi
    if [[ ${HYPERVISOR} == true ]];then
      if [[ ${DISK_STOR} == '' ]];then
        echo "Variable DISK_STOR must be set when HYPERVISOR flag is true.Exiting.."
        exit 1
      fi
    fi
done

# Download image
cd ${WORK_DIR}
wget -N ${SRC_URL}

# Copy downloaded img to qcow2 format
cp ${SRC_IMG} ${IMG_NAME}

# Set the timezone
if [ -n "${TZ+set}" ]; then
  echo "### Setting up TZ ###"
  virt-customize -a ${IMG_NAME} --timezone ${TZ}
fi

# Set locale
if [ ${SETX11} == 'yes' ]; then
  echo "### Setting up keyboard language and locale ###"
  virt-customize -a ${IMG_NAME} \
  --firstboot-command "localectl set-locale LANG=${LOCALLANG}" \
  --firstboot-command "localectl set-x11-keymap ${X11LAYOUT} ${X11MODEL}"
fi

# Install packages
if [[ -n ${VIRTPKG} ]];then
    echo "### Updating system and Installing packages ###"
    virt-customize -a ${IMG_NAME} --update --install ${VIRTPKG}
fi

# Create cloudinit config for vm
echo "### Creating Proxmox Cloud-init config ###"
echo -n > /tmp/99_pve.cfg
cat > /tmp/99_pve.cfg <<EOF
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive ]
EOF

# Upload cloudinit config to image
echo "### Copying Proxmox Cloud-init config to image ###"
virt-customize -a ${IMG_NAME} --upload 99_pve.cfg:/etc/cloud/cloud.cfg.d/

# Update the ssh config
if [[ ${SSH_PASS_AUTH} == 'yes' ]];then 
    echo "### Update SSH configuration to allow user password authentication"
    virt-customize -a ${IMG_NAME} --run-command 'sed -i s/^PasswordAuthentication.*/PasswordAuthentication\ yes/ /etc/ssh/sshd_config'
fi

# I do not like to login as root anywhere so this is enforced on my templates.Your mileage may vary.
echo "### Update SSH configuration to deny root login"
virt-customize -a ${IMG_NAME} --run-command 'sed -i s/^#PermitRootLogin.*/PermitRootLogin\ no/ /etc/ssh/sshd_config'

# Prepere image
echo "### Sysprep image ###"
virt-sysprep -a ${IMG_NAME}

# Sparcify image
echo "### Sparcify image ###"
virt-sparsify --in-place ${IMG_NAME}

# if we are not running in a hypervisor host exit gracefully
if [[ ${HYPERVISOR} != 'true' ]];then
    echo "We are not in a proxmox hypervisor,so we stop after the disk image creation and configuration."
    if [[ ${CLEANUP} == 'yes' ]];then
        rm -v ${SRC_IMG}
        rm -v /tmp/99_pve.cfg
    else
        echo "Image not deleted"
    fi
    echo "Disk image can be found at ${WORK_DIR}/${IMG_NAME}"
    exit 0
fi

# Create the VM and set it as template
qm create ${VMID} --name ${TEMPL_NAME} --memory ${MEM} --balloon ${BALLOON} --cores ${CORES} --bios ${BIOS} --machine ${MACHINE} --net0 virtio,bridge=${NET_BRIDGE}${VLAN:+,tag=$VLAN}
qm set ${VMID} --agent enabled=${AGENT_ENABLE},fstrim_cloned_disks=${FSTRIM}
qm set ${VMID} --ostype ${OS_TYPE}
if [[ ${ZFS} == 'true' ]];then
  qm importdisk ${VMID} ${WORK_DIR}/${IMG_NAME} ${DISK_STOR}
  qm set ${VMID} --scsihw virtio-scsi-single --virtio0 ${DISK_STOR}:vm-${VMID}-disk-0,cache=writethrough,discard=on,iothread=1
  qm set ${VMID} --efidisk0 ${DISK_STOR}:0,efitype=4m,,pre-enrolled-keys=1,size=528K
else
  qm importdisk ${VMID} ${WORK_DIR}/${IMG_NAME} ${DISK_STOR} -format qcow2
  qm set ${VMID} --scsihw virtio-scsi-single --virtio0 ${DISK_STOR}:${VMID}/vm-${VMID}-disk-0.qcow2,cache=writethrough,discard=on,iothread=1
  qm set ${VMID} --efidisk0 ${DISK_STOR}:0,efitype=4m,,format=qcow2,pre-enrolled-keys=1,size=528K
fi
qm set ${VMID} --scsi1 ${DISK_STOR}:cloudinit
qm set ${VMID} --rng0 source=/dev/urandom
qm set ${VMID} --ciuser ${CLOUD_USER}
qm set ${VMID} --cipassword ${CLOUD_PASSWORD}
qm set ${VMID} --boot c --bootdisk virtio0
qm set ${VMID} --tablet 0
qm set ${VMID} --ipconfig0 ip=dhcp

# Apply SSH Key if the value is set
if [[ -n "${SSHKEY+set}" ]]; then
  tmpfile=$(mktemp /tmp/sshkey.XXX.pub)
  echo ${SSHKEY} > $tmpfile
  qm set ${VMID} --sshkey ${tmpfile}
  rm -v ${tmpfile}
fi

if [[ -n ${DISK_SIZE} ]];then
    qm resize ${VMID} virtio0 ${DISK_SIZE}
fi

# Create VM template on proxmox
echo "Creating the VM template"
qm template ${VMID}

# Cleanup
if [ ${CLEANUP} == 'yes' ]; then
  rm -v ${SRC_IMG}
  rm -v /tmp/99_pve.cfg
  rm -v ${IMG_NAME}
else
  echo "Image cannot be deleted"
fi