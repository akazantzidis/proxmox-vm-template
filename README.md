# proxmox-vm-template
Proxmox template creation script with configurable options

The intention of usage of crtmpl.sh is to be used with a input file which sets the basic variables.
An example of the inputs needed is included in the ubuntu.env file included in repo for a fully template creation in a proxmox node.
Typically variable \"HYPERVISOR\"  is set to false and will assume that you want to just create the virtual disk,  
otherwise in a proxmox node you can set it to true to auto-create also the vm template too.

| Variable | default | required | helper var |
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

Example execution:
```sh
 bash crtmpl.sh ubuntu.env
```