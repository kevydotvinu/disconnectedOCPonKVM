#!/bin/bash
# Create Haproxy container image

function CREATE_HAPROXY {
	podman build . -t localhost/kevydotvinu/haproxy
}

CREATE_HAPROXY
