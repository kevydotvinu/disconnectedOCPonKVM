#!/bin/bash
# Download required files for OCP cluster deployment
# - openshift-install
# - openshift-client
# - RHCOS ISO
# - RHCOS rootfs

function ARG_CHECK {
# Take one argument from the commandline: cluster version
if ! [ $ARG -eq 1 ]; then
    echo "Usage: $0 <ocp-cluster-version>"
    exit 1
fi
}

function DOWNLOAD_FILES {
	# Download files and extract it
        wget -O rhcos.iso https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/$(echo $VERSION | cut -d. -f1-2)/$VERSION/rhcos-$VERSION-x86_64-live.x86_64.iso
        wget -O rootfs.img https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/$(echo $VERSION | cut -d. -f1-2)/$VESION/rhcos-$VERSION-x86_64-live-rootfs.x86_64.img
        wget -O openshift-client.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/openshift-client-linux-$VERSION.tar.gz
        wget -O openshift-install.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$VERSION/openshift-install-linux-$VERSION.tar.gz

        tar xfv openshift-client.tar.gz oc
        tar xfv openshift-install.tar.gz openshift-install
        rm -fv openshift-client.tar.gz openshift-install.tar.gz
}

ARG=$#
VERSION=$1

ARG_CHECK
DOWNLOAD_FILES
