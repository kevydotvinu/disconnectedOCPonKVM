#!/bin/bash
# Populate install-config.yaml file using the ENV

function SSH_CHECK {
	if ! [[ -f $(dirname $(pwd))/downloads/id_ed25519.pub ]]; then
		echo "SSH public key is not present in the downloads directory. Please run sshAndPullsecret.sh"
		exit 1
	fi
}

function PULL_SECRET_CHECK {
	if ! [[ -f $(dirname $(pwd))/downloads/pull-secret.json ]]; then
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
  replicas: 2 
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
$(sed -n '/imageContentSources:/,/^$/p' $(dirname $(pwd))/registry/dry-run.txt)
additionalTrustBundle: |
$(cat $(dirname $(pwd))/registry/certs/ca.pem | sed 's/^/    /')
$(cat $(dirname $(pwd))/registry/certs/server.pem | sed 's/^/    /')
EOF
cp install-config.yaml install-config.yaml.bkp
}

SSH_CHECK
PULL_SECRET_CHECK

source $(dirname $(pwd))/env
PULLSECRET=$(cat $(dirname $(pwd))/downloads/pull-secret.json)
SSHKEY=$(cat $(dirname $(pwd))/downloads/id_ed25519.pub)

POPULATE_INSTALL_CONFIG
