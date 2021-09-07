#!/bin/bash
# Populate install-config.yaml file using the ENV

function SSH_CHECK {
	if ! [[ -f ${BASE_DIR}/downloads/id_ed25519.pub ]]; then
		echo "SSH public key is not present in the downloads directory. Please run sshAndPullsecret.sh"
		exit 1
	fi
}

function PULL_SECRET_CHECK {
	if ! [[ -f ${BASE_DIR}/downloads/pull-secret ]]; then
		echo "Pull secret is not present in the downloads directory. Please run sshAndPullsecret.sh"
		exit 1
	fi
}

function POPULATE_INSTALL_CONFIG {
cat << EOF > install-config.yaml
apiVersion: v1
baseDomain: ${DOMAIN}
compute: 
- hyperthreading: Enabled 
  name: worker
  replicas: 0 
controlPlane: 
  hyperthreading: Enabled 
  name: master
  replicas: 3 
metadata:
  name: ${CLUSTER_NAME}
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14 
    hostPrefix: 23 
  networkType: OpenShiftSDN
  serviceNetwork: 
  - 172.30.0.0/16
platform:
  none: {} 
fips: false 
pullSecret: '${PULLSECRET}' 
sshKey: '${SSHKEY}'
EOF
cp install-config.yaml install-config.yaml.bkp
}

SSH_CHECK
PULL_SECRET_CHECK

source ../env
PULLSECRET=$(cat ${BASE_DIR}/downloads/pull-secret)
SSHKEY=$(cat ${BASE_DIR}/downloads/id_ed25519.pub)

POPULATE_INSTALL_CONFIG
