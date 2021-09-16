#!/bin/bash
# Download required files for OCP cluster deployment
# - openshift-install
# - openshift-client
# - RHCOS ISO
# - RHCOS rootfs

source $(dirname $(pwd))/env
if [ -z ${RELEASE} ]; then
echo "RELEASE is unset in" $(dirname $(pwd))/env "file!"; exit 1;
else echo "Using OpenShift" ${RELEASE} "release..."
fi

function GET_PATH {
	RHCOS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -Fe ${RELEASE} | cut -d'/' -f3-)
	[ -n "${RHCOS}" ] || { echo "RHCOS path not found"; exit 1; }
	CLIENTS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e clients/ocp | grep -Fe ${RELEASE} | cut -d'/' -f3-) || echo "Clients path not found"
	[ -n "${CLIENTS}" ] || { echo "Client binaries path not found"; exit 1; }
}

function DOWNLOAD_RHCOS {
	echo "Downloading rhcos.iso..."
        wget -c -q -O rhcos.iso https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live.x86_64.iso && echo "✔ Completed" || echo "✗ Failed"
	echo "Downloading rootfs.img..."
        wget -c -q -O rootfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-rootfs.x86_64.img && echo "✔ Completed" || echo "✗ Failed"
	echo "Downloading kernel..."
        wget -c -q -O kernel https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-kernel-x86_64 && echo "✔ Completed" || echo "Failed"
	echo "Downloading initramfs.img..."
        wget -c -q -O initramfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RELEASE}-x86_64-live-initramfs.x86_64.img && echo "✔ Completed" || echo "✗ Failed"
}

function DOWNLOAD_CLIENTS {
	echo "Downloading openshift-client..."
	wget -c -q -O openshift-client.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-client-linux-${RELEASE}.tar.gz && echo "✔ Completed" || echo "✗ Failed"
	echo "Downloading openshift-install..."
        wget -c -q -O openshift-install.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-install-linux-${RELEASE}.tar.gz && echo "✔ Completed" || echo "✗ Failed"
	echo "Extracting oc and openshift-install binaries..."
        tar xfv openshift-client.tar.gz oc > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
        tar xfv openshift-install.tar.gz openshift-install > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
}

GET_PATH
DOWNLOAD_RHCOS
DOWNLOAD_CLIENTS
