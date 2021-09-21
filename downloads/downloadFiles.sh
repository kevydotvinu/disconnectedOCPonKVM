#!/bin/bash
# Download required files for OCP cluster deployment
# - openshift-install
# - openshift-client
# - RHCOS ISO
# - RHCOS rootfs

source $(dirname $(pwd))/env
if [ -z ${RELEASE} ]; then
echo "RELEASE is unset in" $(dirname $(pwd))/env "file!"; exit 1;
else echo "Using OpenShift" ${RELEASE} "release ..."
fi

function GET_PATH {
	RHCOS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -Fe ${RELEASE} | cut -d'/' -f3-)
	[ -n "${RHCOS}" ] || { echo "RHCOS path not found"; exit 1; }
	CLIENTS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e clients/ocp | grep -Fe ${RELEASE} | cut -d'/' -f3-) || echo "Clients path not found"
	[ -n "${CLIENTS}" ] || { echo "Client binaries path not found"; exit 1; }
}

function DOWNLOAD_RHCOS {
	[[ -f rhcos-${RELEASE}.iso.done ]] || ( echo "Removing old file ..." && rm -fv rhcos.iso )
	echo "Downloading rhcos.iso ..."
        wget -c -q -O rhcos.iso https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live.x86_64.iso && rm -f rhcos-*.iso.done && touch rhcos-${RELEASE}.iso.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f rootfs-${RELEASE}.img.done ]] || ( echo "Removing old file ..." && rm -fv rootfs.img )
	echo "Downloading rootfs.img ..."
        wget -c -q -O rootfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-rootfs.x86_64.img && rm -f rootfs-*.img.done && touch rootfs-${RELEASE}.img.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f kernel-${RELEASE}.done ]] || ( echo "Removing old file ..." && rm -fv kernel )
	echo "Downloading kernel ..."
        wget -c -q -O kernel https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-kernel-x86_64 && rm -f kernel-*.done && touch kernel-${RELEASE}.done && echo "✔ Completed" || echo "Failed"
	[[ -f initramfs-${RELEASE}.img.done ]] || ( echo "Removing old file ..." && rm -fv initramfs.img )
	echo "Downloading initramfs.img ..."
        wget -c -q -O initramfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-initramfs.x86_64.img && rm -f initramfs-*.img.done && touch initramfs-${RELEASE}.img.done && echo "✔ Completed" || echo "✗ Failed"
}

function DOWNLOAD_CLIENTS {
	[[ -f openshift-client-${RELEASE}.tar.gz.done ]] || ( echo -n "Removing old file ..." && rm -fv openshift-client.tar.gz )
	echo "Downloading openshift-client ..."
	wget -c -q -O openshift-client.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-client-linux-${RELEASE}.tar.gz && rm -f openshift-client-*.tar.gz.done && touch openshift-client-${RELEASE}.tar.gz.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f openshift-install-${RELEASE}.tar.gz.done ]] || ( echo -n "Removing old file ..." && rm -fv openshift-install.tar.gz )
	echo "Downloading openshift-install ..."
        wget -c -q -O openshift-install.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-install-linux-${RELEASE}.tar.gz && rm -f openshift-install-*.tar.gz.done && touch openshift-install-${RELEASE}.tar.gz.done && echo "✔ Completed" || echo "✗ Failed"
	echo "Extracting oc and openshift-install binaries ..."
	echo -n "Old file " && rm -fv oc
	echo -n "Old file " && rm -fv openshift-install
        tar xfv openshift-client.tar.gz oc > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
	rm -fv openshift-install
        tar xfv openshift-install.tar.gz openshift-install > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
}

GET_PATH
DOWNLOAD_RHCOS
DOWNLOAD_CLIENTS
