#!/bin/bash
# Stop Squid container

function STOP_HAPROXY {
	podman kill $(sudo podman ps -a | grep squid | awk '{print $1}') 2> /dev/null
	podman rm -f $(sudo podman ps -a | grep squid | awk '{print $1}') 2> /dev/null
}

STOP_HAPROXY
