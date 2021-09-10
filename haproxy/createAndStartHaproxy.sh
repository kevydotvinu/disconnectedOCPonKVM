#!/bin/bash
# Create and start Haproxy container

function STOP_HAPROXY {
	podman kill $(sudo podman ps -a | grep haproxy | awk '{print $1}') 2> /dev/null
	podman rm -f $(sudo podman ps -a | grep haproxy | awk '{print $1}') 2> /dev/null
	
}

function CREATE_HAPROXY {
	podman build . -t localhost/kevydotvinu/haproxy
}

function START_HAPROXY {
	podman run --detach \
	      	--privileged \
	      	--net host \
	      	--volume "$(pwd)/haproxy.cfg:/etc/haproxy/haproxy.cfg" \
	      	--security-opt label=disable \
	      	--name haproxy2 localhost/kevydotvinu/haproxy
}

STOP_HAPROXY
CREATE_HAPROXY
START_HAPROXY
