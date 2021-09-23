#!/bin/bash
# Start registry container image for OCP deployment

function RUN_REGISTRY {
	mkdir -p $DIR/data
	podman run -d --name mirror-registry \
		   --net host --restart=always \
		   -v ${DIR}/data:/var/lib/registry:z \
		   -v ${DIR}/auth:/auth:z \
		   -e "REGISTRY_AUTH=htpasswd" \
		   -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
		   -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
		   -v ${DIR}/certs:/certs:z \
		   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.pem \
		   -e REGISTRY_HTTP_TLS_KEY=/certs/server-key.pem \
		   docker.io/library/registry:2
	cat ${DIR}/certs/ca.pem ${DIR}/certs/server.pem > /etc/pki/ca-trust/source/anchors/registry.crt; update-ca-trust extract
	mkdir -p /etc/docker/certs.d/mirror.ocp.example.local\:5000; cp ${DIR}/certs/server.pem /etc/docker/certs.d/mirror.ocp.example.local\:5000/ca.crt
	sleep 5s; curl -k -u openshift:redhat https://mirror.ocp.example.local:5000/v2/_catalog
	podman login --authfile ${DIR}/auth/auth.json -u openshift -p redhat mirror.ocp.example.local:5000
	jq -c --argjson var "$(jq .auths ${DIR}/auth/auth.json)" '.auths += $var' $(dirname $(pwd))/downloads/pull-secret > $(dirname $(pwd))/downloads/pull-secret.json
}

function STOP_REGISTRY {
	podman kill $(podman ps | grep registry | awk '{print $1}') 2> /dev/null
	podman rm $(podman ps -a | grep registry | awk '{print $1}') 2> /dev/null
	podman rm --storage mirror-registry 2> /dev/null
}

DIR=$(/bin/pwd)
source $(dirname $(pwd))/env

STOP_REGISTRY
sleep 10s
RUN_REGISTRY
