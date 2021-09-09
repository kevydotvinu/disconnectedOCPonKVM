#!/bin/bash
# Connects to bootstrap node

function SSH_CONNECT {
ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${IP}
}

source $(dirname $(pwd))/env
KEY=$(dirname $(pwd))/downloads/id_ed25519
IP=192.168.122.90
USER=core

SSH_CONNECT
