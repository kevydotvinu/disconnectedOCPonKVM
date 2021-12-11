#!/bin/bash
# Populate install-config.yaml file using the ENV

source $(dirname $(pwd))/env

function SSH_CHECK {
	if ! [[ -f $(dirname $(pwd))/downloads/id_ed25519.pub ]]; then
		echo "SSH public key is not present in the downloads directory. Please run sshAndPullsecret.sh"
		exit 1
        else
                SSHKEY=$(cat $(dirname $(pwd))/downloads/id_ed25519.pub)
	fi
}

function PULL_SECRET_CHECK {
	if ! [[ -f $(dirname $(pwd))/downloads/pull-secret.json ]]; then
		echo "Pull secret is not present in the downloads directory. Please run sshAndPullsecret.sh"
		exit 1
        else
                PULLSECRET=$(cat $(dirname $(pwd))/downloads/pull-secret.json)
	fi
}

function DISCONNECTED {
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

function DISCONNECTED_SNC {
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
  replicas: 1 
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

function CONNECTED_PROXY {
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
proxy:
  httpProxy: http://proxy.${CLUSTER_NAME}.${DOMAIN}:4128 
  httpsProxy: http://proxy.${CLUSTER_NAME}.${DOMAIN}:4128 
  noProxy: example.local,192.168.122.0/24 
additionalTrustBundle: |
$(cat $(dirname $(pwd))/proxy/cert/CA.pem | sed 's/^/    /')
EOF
cp install-config.yaml install-config.yaml.bkp
}

function CONNECTED_NON_PROXY {
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
EOF
cp install-config.yaml install-config.yaml.bkp
}

function CONNECTED_PROXY_SNC {
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
  replicas: 1 
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
proxy:
  httpProxy: http://192.168.122.1:4128 
  httpsProxy: http://192.168.122.1:4128 
  noProxy: example.local,192.168.122.0/24 
additionalTrustBundle: |
$(cat $(dirname $(pwd))/proxy/cert/CA.pem | sed 's/^/    /')
EOF
cp install-config.yaml install-config.yaml.bkp
}

function CONNECTED_NON_PROXY_SNC {
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
  replicas: 1 
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

function USAGE {
	echo "OpenShift install-config.yaml file creator"
	echo ""
	echo "This script helps you to create the install-config.yaml file as per your preference"
	echo ""
	echo "Usage:"
        echo "  bash $0 -t [connnected|disconnected|singlenode] -i [proxy|non-proxy]"
	echo ""
	echo "Options"
	echo "  -t: Installation method. One of:"
	echo "      connected | disconnected | single node"
	echo "  -i: Connetivity to the cluster. One of:"
	echo "      proxy | non-proxy" 1>&2; exit 1;
}

function VALIDATE {
	echo "Why disconnected + proxy ?!?" 1>&2; exit 1;
}

while getopts ":t:i:s:" o; do
    case "${o}" in
        t)
            t=${OPTARG}
            ;;
        i)
            i=${OPTARG}
	    ;;
        s)
	    s=${OPTARG}
            if [[ "${t}" == "disconnected" ]]; then
                    if [[ "${i}" == "proxy" ]]; then
                            VALIDATE
                    elif [[ "${i}" == "non-proxy" ]]; then
			    if [[ "${s}" == "single-node" ]]; then
				    SSH_CHECK
				    PULL_SECRET_CHECK
				    DISCONNECTED_SNC && echo "✔ Completed"
			    elif [[ "${s}" == "multi-node" ]]; then
				    SSH_CHECK
                                    PULL_SECRET_CHECK
                                    DISCONNECTED && echo "✔ Completed"
			    else
				    USAGE
			    fi
                    else
                            USAGE
                    fi
            elif [[ "${t}" == "connected" ]]; then
                    if [[ "${i}" == "proxy" ]]; then
			    if [[ "${s}" == "single-node" ]]; then
				    SSH_CHECK
				    PULL_SECRET_CHECK
				    CONNECTED_PROXY_SNC && echo "✔ Completed"
			    elif [[ "${s}" == "multi-node" ]]; then
                                    SSH_CHECK
                                    PULL_SECRET_CHECK
                                    CONNECTED_PROXY && echo "✔ Completed"
			    else
				    USAGE
			    fi
                    elif [[ "${i}" == "non-proxy" ]]; then
                            if [[ "${s}" == "single-node" ]]; then
				    SSH_CHECK
				    PULL_SECRET_CHECK
				    CONNECTED_NON_PROXY_SNC && echo "✔ Completed"
			    elif [[ "${s}" == "multi-node" ]]; then
                                    SSH_CHECK
                                    PULL_SECRET_CHECK
                                    CONNECTED_NON_PROXY && echo "✔ Completed"
                            echo "⚠ Please enable guest VM internet"
                            echo "❱ bash configureHost.sh -s vms-internet"
			    else
				    USAGE
			    fi
                    else
                            USAGE
                    fi
            else
                    USAGE
            fi
            ;;
        *)
            USAGE
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${t}" ] || [ -z "${i}" ] || [ -z "${s}" ]; then
    USAGE
fi
