#!/bin/bash
# Create Haproxy container image

function CREATE_HAPROXY {
	podman build . -t localhost/kevydotvinu/haproxy --security-opt label=disable
}

CREATE_HAPROXY
