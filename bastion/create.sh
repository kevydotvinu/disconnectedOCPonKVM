#!/bin/bash
#
# NAME
#	Create virtual machines in kvm with cloud images
#
# SYNOPSIS
#	bash create_vm.sh
#
# DESCRIBTION
#	It creates VM in KVM with cloud images instantly
#
# CHANGELOG
#	- Fri Feb 9 2018 <kevy.vinu@gmail.com>
#	* Original Code

function IMAGE_CHECK {
# Take one argument from the commandline: VM name
if ! [[ -f $DIR/*.qcow2 ]]; then
    echo "No image present"
    echo "Download from 'https://access.redhat.com/downloads/content/69/ver=/rhel---7/7.9/x86_64/product-software' and save it here as rhel7.qcow2"
    exit 1
fi
}

function SSH_CHECK {
# Take one argument from the commandline: VM name
if ! [[ -f ../downloads/id_ed25519.pub ]]; then
    echo "No SSH key present"
    echo "Please run sshAndPullsecret.sh first"
    exit 1
fi
}

function ARG_CHECK {
# Take one argument from the commandline: VM name
if ! [ $ARG -eq 1 ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi
}

function DOMAIN_CHECK {
# Check if domain already exists
virsh dominfo $NAME > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo -e -n "[\e[31mWARNING\e[m] $NAME already exists.  "
    read -p "Do you want to overwrite $NAME [y/N]? " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo -e "\nNot overwriting $NAME. Exiting..."
        exit 1
    fi
fi
}

function POPULATE_FILES {
# Start clean
rm -rf $DIR/$NAME
mkdir -p $DIR/$NAME

pushd $DIR/$NAME > /dev/null

# Create log file
touch $NAME.log

echo "$(date -R) Destroying the $NAME domain (if it exists)..."

# Remove domain with the same name
virsh destroy $NAME >> $NAME.log 2>&1
virsh undefine $NAME >> $NAME.log 2>&1

# cloud-init config: set hostname, remove cloud-init package, and add ssh-key 
cat > $USER_DATA << EOF
#cloud-config

# Hostname management
preserve_hostname: False
hostname: $NAME
fqdn: $NAME.example.local

# Remove cloud-init when finished with it
runcmd:
  - [ yum, -y, remove, cloud-init ]
  - [ apt-get, -y, remove, cloud-init ]

# Install packages
packages:
  - cloud-initramfs-growroot

# Configure where output will go
output: 
  all: ">> /var/log/cloud-init.log"

# Create users
users:
  - name: $USERNAME
    plain_text_passwd: 'password'
    lock-passwd: False
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
ssh_pwauth: True

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True
ssh_genkeytypes: ['rsa', 'ecdsa']

# Install my public ssh key to the first user-defined user configured 
# in cloud.cfg in the template (which is centos for CentOS cloud images)
ssh_authorized_keys:
  - $SSH_PUBLIC_KEY
EOF

echo "instance-id: $NAME; local-hostname: $NAME" > $META_DATA

echo "$(date -R) Copying template image..."
cp $IMAGE $DISK

# Create CD-ROM ISO with cloud-init config
echo "$(date -R) Generating ISO for cloud-init..."
genisoimage -output $CI_ISO -volid cidata -joliet -r $USER_DATA $META_DATA &>> $NAME.log
}

function CREATE_VM {
echo "$(date -R) Installing the domain and adjusting the configuration..."
echo
echo -e "[\e[36mINFO\e[m] Installing with the following parameters:"
echo "virt-install --import --name $NAME --ram $MEM --vcpus $CPUS --disk
$DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network
bridge=$BRIDGE,model=virtio,mac=$MAC --os-type=linux --os-variant=rhel6 --noautoconsole"

virt-install --import --name $NAME --ram $MEM --vcpus $CPUS --disk \
$DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network \
bridge=$BRIDGE,model=virtio,mac=$MAC --os-type=linux --os-variant=rhel6 --noautoconsole

echo "Please wait while we retrive your IP"
MAC=$(virsh dumpxml $NAME | awk -F\' '/mac address/ {print $2}')
while true
do
    IP=$(grep -B1 $MAC /var/lib/libvirt/dnsmasq/default.leases | head \
         -n 1 | awk '{print $3}' | sed -e s/\"//g -e s/,//)
    if [ "$IP" = "" ]
    then
        sleep 2
	echo -n .
    else
        break
    fi
done

# Eject cdrom
echo
echo "$(date -R) Cleaning up cloud-init..."
virsh change-media $NAME hdc --eject --config >> $NAME.log

# Remove the unnecessary cloud init files
rm -f $USER_DATA $CI_ISO
echo -e "$(date -R) DONE. SSH to \e[1;36m$NAME\e[m using \e[31m$IP\e[m, with  username \e[35m$USERNAME\e[m."
popd > /dev/null
}

# Declare variables
ARG=$#
NAME=$1
DIR=$(/bin/pwd)
MEM=1024
CPUS=1
BRIDGE=virbr0
MAC=52:54:00:2e:1c:00
# Cloud init files
USER_DATA=user-data
META_DATA=meta-data
CI_ISO=$NAME-cidata.iso
DISK=OS.qcow2
DISK_DATA=DATA.qcow2
SSH_CHECK
SSH_PUBLIC_KEY="$(cat ../downloads/id_ed25519.pub)"
IMAGE_CHECK
IMAGE=$DIR/rhel7.qcow2
USERNAME=user

ARG_CHECK
DOMAIN_CHECK
POPULATE_FILES
CREATE_VM
