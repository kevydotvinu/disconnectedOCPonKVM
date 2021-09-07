#!/bin/bash
# Create container image registry for OCP deployment

function POPULATE_AUTH {
	rm -rvf $DIR/auth
	mkdir -p $DIR/auth
	pushd $DIR/auth > /dev/null
	htpasswd -bBc htpasswd openshift redhat
	popd > /dev/null
}

function POPULATE_CERTS {
	rm -rvf $DIR/certs
	mkdir -p $DIR/certs
	pushd $DIR/certs > /dev/null
cat << EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "server": {
        "expiry": "87600h",
        "usages": [
          "signing",
          "key encipherment",
          "server auth"
        ]
      },
      "client": {
        "expiry": "87600h",
        "usages": [
          "signing",
          "key encipherment",
          "client auth"
        ]
      }
    }
  }
}
EOF
cat << EOF > ca-csr.json
{
  "CN": "Red Hat Inc.",
  "hosts": [
    "bastion.example.com"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "ST": "Washington",
      "L": "Seattle",
      "OU": "Inc."
    }
  ]
}
EOF
cat << EOF > server.json
{
  "CN": "Red Hat Inc.",
  "hosts": [
    "bastion.example.com"
  ],
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [
    {
      "C": "US",
      "ST": "Washington",
      "L": "Seattle",
      "OU": "Inc."
    }
  ]
}
EOF
	popd > /dev/null
}

function RUN_REGISTRY {
	mkdir -p $DIR/data
	podman run -d --name mirror-registry \
		   -p 5000:5000 --restart=always \
		   -v ./data:/var/lib/registry:z \
		   -v ./auth:/auth:z \
		   -e "REGISTRY_AUTH=htpasswd" \
		   -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
		   -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
		   -v ./certs:/certs:z \
		   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.pem \
		   -e REGISTRY_HTTP_TLS_KEY=/certs/server-key.pem \
		   docker.io/library/registry:2
}

function STOP_REGISTRY {
	podman kill $(podman ps | grep registry | awk '{print $1}')
	podman rm $(podman ps -a | grep registry | awk '{print $1}')
}

DIR=$(/bin/pwd)

POPULATE_AUTH
POPULATE_CERTS
STOP_REGISTRY
RUN_REGISTRY
