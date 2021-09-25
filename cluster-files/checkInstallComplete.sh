#!/bin/bash
# Connects to cluster

function SET_ENV {
	export PATH=$PATH:$(dirname $(pwd))/downloads
	export KUBECONFIG=$(dirname $(pwd))/cluster-files/auth/kubeconfig
}

function OC_CONNECT {
	openshift-install --log-level debug wait-for install-complete
}

SET_ENV
OC_CONNECT
