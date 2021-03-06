#!/bin/bash
# Connects to cluster

function SET_ENV {
	export PATH=$PATH:$(dirname $(pwd))/downloads
	export KUBECONFIG=$(dirname $(pwd))/cluster-files/auth/kubeconfig
}

function APPROVE_CSR {
	while true; do
	oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
	sleep 10s
	done
}

function WAIT_FOR_COMPLETE {
	for i in 1 2 3; do openshift-install --log-level debug wait-for install-complete; if [[ $? == 0 ]]; then break; fi; done
}

SET_ENV
APPROVE_CSR &
PID=$!
trap "kill ${PID}" EXIT SIGINT SIGTERM
WAIT_FOR_COMPLETE
