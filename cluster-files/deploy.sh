#!/bin/bash

source $(dirname $(pwd))/env

function CONFIGURE_HOST {
	pushd $(dirname $(pwd)) > /dev/null
	bash configureHost.sh -s all
	popd > /dev/null
}

function DOWNLOAD_FILES {
	pushd $(dirname $(pwd))/downloads > /dev/null
	bash downloadFiles.sh
	bash sshAndPullsecret.sh $OCM_TOKEN
	popd > /dev/null
}

function SETUP_REGISTRY {
	pushd $(dirname $(pwd))/registry > /dev/null
	bash createRegistry.sh
	bash startRegistry.sh
	bash mirror.sh
	popd > /dev/null
}

function SETUP_HAPROXY {
	pushd $(dirname $(pwd))/haproxy > /dev/null
	bash createHaproxy.sh
	bash startHaproxy.sh
	popd > /dev/null
}

function CREATE_CLUSTER_FILES {
	bash install-config.sh -t disconnected -i non-proxy -s multi-node
	bash createManifestsAndIgnitionConfig.sh
}

function DEPLOY {
	bash createNodes.sh
}

function CHECK {
	bash checkInstallComplete.sh
}

[[ -f host-configure-${RELEASE}.done ]] || ( CONFIGURE_HOST && rm -f host-configure-*.done && touch host-configure-${RELEASE}.done )
echo "Host configuration done"
[[ -f download-files-${RELEASE}.done ]] || ( DOWNLOAD_FILES && rm -f download-files-*.done && touch download-files-${RELEASE}.done )
echo "Downloads done"
[[ -f setup-registry-${RELEASE}.done ]] || ( SETUP_REGISTRY && rm -f setup-registry-*.done  && touch setup-registry-${RELEASE}.done )
echo "Registry configuration done"
[[ -f setup-haproxy-${RELEASE}.done ]] || ( SETUP_HAPROXY && rm -f setup-haproxy-*.done  && touch setup-haproxy-${RELEASE}.done )
echo "Haproxy configuration done"
[[ -f cluster-files-${RELEASE}.done ]] || ( CREATE_CLUSTER_FILES && rm -f cluster-files-*.done  && touch cluster-files-${RELEASE}.done )
echo "Cluster files created"
[[ -f deploy-${RELEASE}.done ]] || ( DEPLOY && rm -f deploy-*.done  && touch deploy-${RELEASE}.done )
echo "Cluster deploying ..."
CHECK
if [[ $? == 0 ]]; then echo "Cluster deployed"; else echo "Cluster not deployed"; fi
