#!/bin/bash

function PATCH_OH {
	oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
}

function PAUSE_UNPAUSE_MCP {
	oc patch --type=merge --patch='{"spec":{"paused":'${1}'}}' machineconfigpool/${2}
}

function CREATE_OPERATOR_SOURCE {
	oc create -f manifests/
}

function WAIT_MCP {
	oc wait --for=condition=Updated=True mcp ${1} --timeout=2m
}

source $(dirname $(dirname $(pwd)))/env
KUBECONFIG=$(dirname $(dirname $(pwd)))/cluster-files/auth/kubeconfig
PATCH_OH
PAUSE_UNPAUSE_MCP true master
PAUSE_UNPAUSE_MCP true worker
CREATE_OPERATOR_SOURCE
PAUSE_UNPAUSE_MCP false worker
WAIT_MCP worker
PAUSE_UNPAUSE_MCP false master
WAIT_MCP master
