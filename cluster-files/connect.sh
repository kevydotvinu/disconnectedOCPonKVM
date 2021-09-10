#!/bin/bash
# Connects to cluster

function SET_ENV {
	export PATH=$PATH:$(dirname $(pwd))/downloads
	export KUBECONFIG=$(dirname $(pwd))/cluster-files/auth/kubeconfig
}

function OC_CONNECT {
	oc get co
}

SET_ENV
OC_CONNECT
