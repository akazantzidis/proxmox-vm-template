# proxmox-vm-template
VM template creation script with configurable options

| Variable | Default | Required | Description|
| -------- | ------- | -------- | ---------- |
| SRC_VER | - | no | yes|
| SRC_URL | - | yes | no|
| SRC_IMG | ${SRC_URL##*/} | yes | yes |
| IMG_NAME | ${SRC_IMG/.img/.qcow2} | yes | yes |
| WORK_DIR | /tmp | yes | no |
| CLEANUP | yes | no | no |
| OSNAME | - | yes| yes |
| TEMPL_NAME_DEFAULT | - | yes | yes |
| TEMPL_NAME | TEMPL_NAME_DEFAULT | no | yes |
| VMID_DEFAULT | 1000 | yes | yes |
| VMID | $VMID_DEFAULT | no | yes|
| CLOUD_USER_DEFAULT | - | yes | yes |
| CLOUD_USER | $CLOUD_USER_DEFAULT | no | yes |
| CLOUD_PASSWORD_DEFAULT | RANDOM-GENERATED | no | yes |
| CLOUD_PASSWORD | CLOUD_PASSWORD_DEFAULT | no | yes |
| MEM | 1024 | no | no |
| BALLOON | 1 | no | no | 
| DISK_STOR | - | yes | no |
| NET_BRIDGE | vmbr0 | no | no |
| ZFS | - | true | no |
| CORES | 1 | false | no |
| OS_TYPE | l26 | no | no |
| AGENT_ENABLE | 1 | no | no |
| FSTRIM | 1 | no | no |
| BIOS | ovfm | no | no |
| MACHINE | q35 | no | no |
| VIRTPKG | - | no | no |
| TZ | - | yes | no |
| SETX11 | yes | no | no |
| X11LAYOUT | us | no | no |
| X11MODEL | pc105 | no | no |
| LOCALLANG | en_us.UTF-8| | |
| HYPERVISOR | false| no | no |
| SSH_PASS_AUTH | no | no | no |
| SSHKEY | - | no | no |
| VLAN | - | no | no |
| DISK_SIZE | - | no | no |


Usage:  

The intention of usage of crtmpl.sh is to be used with a input file which sets the basic variables.
When is executed in  a proxmox node you can create the vm template setting HDD_STOR and HYPERVISOR variables accordingly.

Example execution:
```sh
 bash crtmpl.sh ubuntu.env
```

Example ubuntu disk only creation:
```sh
SRC_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
TEMPL_NAME_DEFAULT="ubuntu2204"
VMID_DEFAULT="999"
CLOUD_USER_DEFAULT="ubuntu"
```

Example ubuntu template on proxmox host:
```sh
SRC_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
TEMPL_NAME_DEFAULT="ubuntu2204"
VMID_DEFAULT="1000"
CLOUD_USER_DEFAULT="ubuntu"
DISK_STOR="HDD"
HYPERVISOR="true" 
```

Example ubuntu template on proxmox host with ZFS backend:
```sh
SRC_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
TEMPL_NAME_DEFAULT="ubuntu2204"
VMID_DEFAULT="10001"
CLOUD_USER_DEFAULT="ubuntu"
DISK_STOR="SUPERFASTSTORAGE"
ZFS="true" 
```
Example fedora template on proxmox host with ZFS storage backend:
```sh
SRC_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/x86_64/images/Fedora-Cloud-Base-38-1.6.x86_64.qcow2"
TEMPL_NAME_DEFAULT="fedora38"
VMID_DEFAULT="2000"
CLOUD_USER_DEFAULT="fedora"
DISK_STOR="SUPERFASTSTORAGE"
ZFS="true"
HYPERVISOR="true"
```