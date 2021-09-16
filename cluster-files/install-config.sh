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
  httpProxy: http://192.168.122.1:3128 
  httpsProxy: http://192.168.122.1:3128 
  noProxy: example.local,192.168.122.0/24 
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

function SNC_PROXY {
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
  httpProxy: http://192.168.122.1:3128 
  httpsProxy: http://192.168.122.1:3128 
  noProxy: example.local,192.168.122.0/24 
EOF
cp install-config.yaml install-config.yaml.bkp
}

function SNC_NON_PROXY {
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
	echo "Usage: bash $0 -t <connnected|disconnected|singlenode> -i <proxy|non-proxy>" 1>&2; exit 1;
}

function VALIDATE {
	echo "Why disconnected + proxy ?!?" 1>&2; exit 1;
}

while getopts ":t:i:" o; do
    case "${o}" in
        t)
            t=${OPTARG}
            ;;
        i)
            i=${OPTARG}
	    if [[ "${t}" == "disconnected" ]]; then
		    if [[ "${i}" == "proxy" ]]; then
			    VALIDATE
		    elif [[ "${i}" == "non-proxy" ]]; then
                            SSH_CHECK
                            PULL_SECRET_CHECK
			    DISCONNECTED && echo "✔ Completed"
		    else
			    USAGE
		    fi
	    elif [[ "${t}" == "connected" ]]; then
		    if [[ "${i}" == "proxy" ]]; then
                            SSH_CHECK
                            PULL_SECRET_CHECK
			    CONNECTED_PROXY && echo "✔ Completed"
		    elif [[ "${i}" == "non-proxy" ]]; then
                            SSH_CHECK
                            PULL_SECRET_CHECK
			    CONNECTED_NON_PROXY && echo "✔ Completed"
                            echo "⚠ Please enable MASQUERADE"
                            echo "❱ iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE"
		    else 
			    USAGE
		    fi
            elif [[ "${t}" == "singlenode" ]]; then
		    if [[ "${i}" == "proxy" ]]; then
                            SSH_CHECK
                            PULL_SECRET_CHECK
			    SNC_PROXY && echo "✔ Completed"
		    elif [[ "${i}" == "non-proxy" ]]; then
                            SSH_CHECK
                            PULL_SECRET_CHECK
			    SNC_NON_PROXY && echo "✔ Completed"
                            echo "⚠ Please enable MASQUERADE"
                            echo "❱ iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE"
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

if [ -z "${t}" ] || [ -z "${i}" ]; then
    USAGE
fi
