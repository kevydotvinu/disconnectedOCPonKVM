#!/bin/bash
# Connects to bootstrap node

function SSH_CONNECT {
ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${IP}
}

source ../../env
KEY=${BASE_DIR}/downloads/id_ed25519
IP=192.168.122.94
USER=core

SSH_CONNECT
