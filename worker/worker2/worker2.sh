#!/bin/bash
# Create bootstrap VM

function CHECK_DISK {
	if ! [[ -f $(pwd)/worker2.img ]]; then
		qemu-img create worker2.img 60G
	fi
}

function CREATE_VM {
MAC=$(ip a s $(virsh net-info default | awk '/Bridge:/{print $2}') | awk '/ether /{print $2}' | cut -f1-4 -d':')
MAC=$MAC:91:96
VIRT_NET=default
VM_NAME=worker2
WEB_IP=192.168.122.1
WEB_PORT=8080
ISO=$(dirname $(dirname $(pwd)))/downloads/rhcos.iso
DISK=$(pwd)/${VM_NAME}.img
virsh destroy ${VM_NAME} 2> /dev/null
virsh undefine ${VM_NAME} 2> /dev/null
virt-install --name ${VM_NAME} \
	     --disk ${DISK} \
	     --ram 16000 \
	     --vcpus 4 \
	     --os-type linux \
	     --os-variant rhel7 \
	     --network network=${VIRT_NET},mac=${MAC} \
	     --pxe \
	     --boot menu=on,useserial=on \
	     --nographics
#	     --location ${ISO}
#	     --extra-args "nomodeset rd.neednet=1 console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.install_dev=vda coreos.live.rootfs_url=http://${WEB_IP}:${WEB_PORT}/downloads/rootfs.img coreos.inst.ignition_url=http://${WEB_IP}:${WEB_PORT}/cluster-files/worker.ign"
}

source $(dirname $(dirname $(pwd)))/env

CHECK_DISK
CREATE_VM
