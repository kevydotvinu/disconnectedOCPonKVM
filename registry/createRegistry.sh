#!/bin/bash
# Create registry container image for OCP deployment

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
  "CN": "Red Hat, Inc.",
  "hosts": [
    "mirror.${CLUSTER_NAME}.${DOMAIN}",
    "10.74.253.82",
    "192.168.122.1",
    "127.0.0.1",
    "localhost"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "India",
      "ST": "Maharashtra",
      "L": "Pune",
      "OU": "Inc."
    }
  ]
}
EOF
cat << EOF > server.json
{
  "CN": "Red Hat, Inc.",
  "hosts": [
    "mirror.${CLUSTER_NAME}.${DOMAIN}",
    "10.74.253.82",
    "192.168.122.1",
    "127.0.0.1",
    "localhost"
  ],
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [
    {
      "C": "India",
      "ST": "Maharashtra",
      "L": "Pune",
      "OU": "Inc."
    }
  ]
}
EOF
	popd > /dev/null
	wget --quiet https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64 -O ${DIR}/cfssljson
	wget --quiet https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64 -O ${DIR}/cfssl
	chmod +x ${DIR}/cfssl ${DIR}/cfssljson
	pushd $DIR/certs > /dev/null
	$(dirname $(pwd))/cfssl version ; $(dirname $(pwd))/cfssljson --version
	$(dirname $(pwd))/cfssl gencert -initca ca-csr.json | $(dirname $(pwd))/cfssljson -bare ca -
	$(dirname $(pwd))/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | $(dirname $(pwd))/cfssljson -bare server
	popd > /dev/null
}

DIR=$(/bin/pwd)
source $(dirname $(pwd))/env

POPULATE_AUTH
POPULATE_CERTS
