#!/bin/bash
# Connects to cluster

function SET_ENV {
	OC=$(dirname $(pwd))/downloads/oc
	KUBECONFIG=$(dirname $(pwd))/cluster-files/auth/kubeconfig
}

function CSR_APPROVE {
	$OC get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
}

SET_ENV
CSR_APPROVE
