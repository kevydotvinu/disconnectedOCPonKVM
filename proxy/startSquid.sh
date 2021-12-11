#!/bin/bash
# Start Squid container

function STOP_HAPROXY {
	podman kill $(sudo podman ps -a | grep squid | awk '{print $1}') 2> /dev/null
	podman rm -f $(sudo podman ps -a | grep squid | awk '{print $1}') 2> /dev/null
}

function START_HAPROXY {
	podman run --detach \
		--env CLUSTER_NAME=${CLUSTER_NAME} \
		--env DOMAIN=${DOMAIN} \
	      	--net host \
	      	--security-opt label=disable \
		--volume $(pwd)/conf/squid.conf:/etc/squid/squid.conf \
		--volume $(pwd)/cert:/etc/squid-cert \
		--volume $(pwd)/cache:/var/cache/squid \
		--volume $(pwd)/log:/var/log/squid \
	      	--name squid localhost/kevydotvinu/squid
}

source $(dirname $(pwd))/env
STOP_HAPROXY
sleep 5s
START_HAPROXY
