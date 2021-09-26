#!/bin/bash
# Connects to rhel8 node

function SSH_CONNECT {
ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${IP}
}

source $(dirname $(pwd))/env
KEY=$(dirname $(pwd))/downloads/id_ed25519
IP=192.168.122.98
USER=user

SSH_CONNECT
