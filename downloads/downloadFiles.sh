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
	RELEASE_CUT=$(echo ${RELEASE} | cut -d"." -f1-2)
	if echo ${RELEASE} | grep -qE '(^[0-9][.][0-9][.][0-9]$|^[0-9][.][0-9][.][0-9][0-9]$|^[0-9][.][0-9][0-9][.][0-9][0-9]$)'; then
		RHCOS_EQ_VER=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -Fe ${RELEASE} | cut -d'/' -f3-)
		RHCOS_LE_VER=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -e ${RELEASE_CUT}'[.][0-9]$' | head -1 | cut -d'/' -f3-)
		RHCOS=${RHCOS_EQ_VER:=$RHCOS_LE_VER}
		if [[ ${RHCOS_EQ_VER} == ${RHCOS_LE_VER} ]]; then
			RHCOS_RELEASE=${RELEASE}
		else
			RHCOS_RELEASE=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -e ${RELEASE_CUT}'[.][0-9]$' | head -1 | rev | cut -d'/' -f1 | rev)
		fi
		[ -n "${RHCOS}" ] || { echo "RHCOS path not found"; exit 1; }
		[ -n "${RHCOS_RELEASE}" ] || { echo "RHCOS path not found"; exit 1; }
	else
		RHCOS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e dependencies/rhcos | grep -Fe ${RELEASE} | cut -d'/' -f3-)
		RHCOS_RELEASE=${RELEASE}
		[ -n "${RHCOS}" ] || { echo "RHCOS path not found"; exit 1; }
	fi
	CLIENTS=$(curl -s https://mirror.openshift.com/pub/DIRECTORY_SIZES.txt | grep -e x86_64 | grep -e clients/ocp | grep -Fe ${RELEASE} | cut -d'/' -f3-) || echo "Clients path not found"
	[ -n "${CLIENTS}" ] || { echo "Client binaries path not found"; exit 1; }
}

function DOWNLOAD_RHCOS {
	[[ -f rhcos-${RHCOS_RELEASE}.iso.done ]] || ( echo "Removing old file ..." && rm -fv rhcos.iso )
	echo "Downloading rhcos.iso ..."
        wget -c -q -O rhcos.iso https://mirror.openshift.com/${RHCOS}/rhcos-${RHCOS_RELEASE}-x86_64-live.x86_64.iso && rm -f rhcos-*.iso.done && touch rhcos-${RHCOS_RELEASE}.iso.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f rootfs-${RHCOS_RELEASE}.img.done ]] || ( echo "Removing old file ..." && rm -fv rootfs.img )
	echo "Downloading rootfs.img ..."
        wget -c -q -O rootfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RHCOS_RELEASE}-x86_64-live-rootfs.x86_64.img && rm -f rootfs-*.img.done && touch rootfs-${RHCOS_RELEASE}.img.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f kernel-${RHCOS_RELEASE}.done ]] || ( echo "Removing old file ..." && rm -fv kernel )
	echo "Downloading kernel ..."
        wget -c -q -O kernel https://mirror.openshift.com/${RHCOS}/rhcos-${RHCOS_RELEASE}-x86_64-live-kernel-x86_64 && rm -f kernel-*.done && touch kernel-${RHCOS_RELEASE}.done && echo "✔ Completed" || echo "Failed"
	[[ -f initramfs-${RHCOS_RELEASE}.img.done ]] || ( echo "Removing old file ..." && rm -fv initramfs.img )
	echo "Downloading initramfs.img ..."
        wget -c -q -O initramfs.img https://mirror.openshift.com/${RHCOS}/rhcos-${RHCOS_RELEASE}-x86_64-live-initramfs.x86_64.img && rm -f initramfs-*.img.done && touch initramfs-${RHCOS_RELEASE}.img.done && echo "✔ Completed" || echo "✗ Failed"
}

function DOWNLOAD_CLIENTS {
	[[ -f openshift-client-${RELEASE}.tar.gz.done ]] || ( echo "Removing old file ..." && rm -fv openshift-client.tar.gz )
	echo "Downloading openshift-client ..."
	wget -c -q -O openshift-client.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-client-linux-${RELEASE}.tar.gz && rm -f openshift-client-*.tar.gz.done && touch openshift-client-${RELEASE}.tar.gz.done && echo "✔ Completed" || echo "✗ Failed"
	[[ -f openshift-install-${RELEASE}.tar.gz.done ]] || ( echo "Removing old file ..." && rm -fv openshift-install.tar.gz )
	echo "Downloading openshift-install ..."
        wget -c -q -O openshift-install.tar.gz https://mirror.openshift.com/${CLIENTS}/openshift-install-linux-${RELEASE}.tar.gz && rm -f openshift-install-*.tar.gz.done && touch openshift-install-${RELEASE}.tar.gz.done && echo "✔ Completed" || echo "✗ Failed"
	echo "Extracting oc binary ..."
	echo "Removing old file ..." && rm -fv oc
        tar xfv openshift-client.tar.gz oc > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
	echo "Extracting openshift-install binary ..."
	echo "Removing old file ..." && rm -fv openshift-install
        tar xfv openshift-install.tar.gz openshift-install > /dev/null 2>&1 && echo "✔ Completed" || echo "✗ Failed"
}

GET_PATH
DOWNLOAD_RHCOS
DOWNLOAD_CLIENTS
