#!/bin/bash
# Create bootstrap VM

function CHECK_DISK {
	if ! [[ -f $(pwd)/bootstrap.img ]]; then
		qemu-img create bootstrap.img 60G
	fi
}

function CREATE_VM {
MAC=$(ip a s $(virsh net-info default | awk '/Bridge:/{print $2}') | awk '/ether /{print $2}' | cut -f1-4 -d':')
MAC=$MAC:91:90
VIRT_NET=default
VM_NAME=bootstrap
WEB_IP=192.168.122.1
WEB_PORT=8080
ISO=$(dirname $(pwd))/downloads/rhcos.iso
ROOTFS=http://${WEB_IP}:${WEB_PORT}/downloads/rootfs.img
IGNITION=http://${WEB_IP}:${WEB_PORT}/cluster-files/bootstrap.ign
DISK=$(pwd)/bootstrap.img
virsh destroy ${VM_NAME} 2> /dev/null
virsh undefine ${VM_NAME} 2> /dev/null
virt-install --name ${VM_NAME} \
	     --disk ${DISK} \
	     --ram 16000 \
	     --vcpus 4 \
	     --os-type linux \
	     --os-variant rhel7 \
	     --network network=${VIRT_NET},mac=${MAC} \
	     --location ${ISO} \
	     --nographics \
	     --noautoconsole \
	     --extra-args "nomodeset rd.neednet=1 console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.install_dev=vda coreos.live.rootfs_url=${ROOTFS} coreos.inst.ignition_url=${IGNITION}"
}

source $(dirname $(pwd))/env

CHECK_DISK > /dev/null
( CREATE_VM 1>/dev/null && echo "✔ Bootstrap VM created" ) || echo "✗ Error: Bootstrap VM creation failed"
