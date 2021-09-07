#!/bin/bash
# Create and start Haproxy container

function CREATE_HAPROXY {
	podman build . -t localhost/kevydotvinu/haproxy
}

function START_HAPROXY {
	podman run --detach \
	      	--privileged \
	      	--net host \
	      	--volume "$(pwd)/haproxy.cfg:/etc/haproxy/haproxy.cfg" \
	      	--security-opt label=disable \
	      	--name haproxy localhost/kevydotvinu/haproxy
}

CREATE_HAPROXY
START_HAPROXY
