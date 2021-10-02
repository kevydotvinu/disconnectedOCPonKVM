#!/bin/bash

function CREATE_NODES {
	pushd $(dirname $(pwd))/bootstrap > /dev/null
	bash bootstrap.sh
	popd > /dev/null
	pushd $(dirname $(pwd))/master/master0 > /dev/null
	bash master0.sh
	popd > /dev/null
	pushd $(dirname $(pwd))/master/master1 > /dev/null
	bash master1.sh
	popd > /dev/null
	pushd $(dirname $(pwd))/master/master2 > /dev/null
	bash master2.sh
	popd > /dev/null
	pushd $(dirname $(pwd))/worker/worker0 > /dev/null
	bash worker0.sh
	popd > /dev/null
	pushd $(dirname $(pwd))/worker/worker1 > /dev/null
	bash worker1.sh
	popd > /dev/null
}

function WAIT_FOR_REBOOT {
	sp='/-\|'
	sc=0
	
	spin() {
	   printf "\r[${sp:sc++:1}] $1"
	   ((sc==${#sp})) && sc=0
	}

	endspin() {
	   printf "\r%s\n" "$@"
	}
	
	until [[ $(virsh -q list | wc -c) -eq 0 ]]
	do spin "Waiting for the installation and restart ..."
	sleep 0.5
	done
	endspin
}

function START_NODES {
	for i in bootstrap master0 master1 master2 worker0 worker1; do virsh start $i > /dev/null; done; echo "✔ All nodes are restarted"
}

CREATE_NODES
WAIT_FOR_REBOOT
START_NODES
