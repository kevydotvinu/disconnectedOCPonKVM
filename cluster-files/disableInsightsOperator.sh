#!/bin/bash

function MODIFY_PULLSECRET {
	jq -c 'del(.auths | ."cloud.openshift.com")' ${ROOT_DIR}/downloads/pull-secret.json > ${ROOT_DIR}/downloads/pull-secret-without-cloud-cred.json
}

function REPLACE_PULLSECRET {
	oc delete secret pull-secret -n openshift-config
	oc create secret docker-registry pull-secret --from-file=.dockerconfigjson=${ROOT_DIR}/downloads/pull-secret-without-cloud-cred.json -n openshift-config
}

ROOT_DIR=$(dirname $(pwd))
KUBECONFIG=$(pwd)/auth/kubeconfig

MODIFY_PULLSECRET
REPLACE_PULLSECRET
