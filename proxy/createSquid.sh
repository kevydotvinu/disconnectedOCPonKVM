#!/bin/bash
# Create Squid container image

function CREATE_HAPROXY {
	podman build . -t localhost/kevydotvinu/squid --security-opt label=disable
}

CREATE_HAPROXY
