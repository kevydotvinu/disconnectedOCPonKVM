#!/bin/bash
# Download pull secret using OpenShift Cluster Manager API Token

function ARG_CHECK {
# Take one argument from the commandline: API Token
if ! [ $ARG -eq 1 ]; then
    echo "Usage: $0 '<OCM API Token>'"
    echo "You need to authenticate using a Bearer token, which you can get from the link: https://cloud.redhat.com/openshift/token"
    exit 1
fi
}

function DOWNLOAD_PULLSECRET {
	export BEARER=$(curl \
		--silent \
		--data-urlencode "grant_type=refresh_token" \
		--data-urlencode "client_id=cloud-services" \
		--data-urlencode "refresh_token=${OCM_API_TOKEN}" \
		https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
		jq -r .access_token)
	curl -s -X POST https://api.openshift.com/api/accounts_mgmt/v1/access_token --header "Content-Type:application/json" --header "Authorization: Bearer $BEARER" > pull-secret
}

function SSH_KEY {
	ssh-keygen -t ed25519 -N '' -f id_ed25519
}

ARG=$#
OCM_API_TOKEN=$1

ARG_CHECK
DOWNLOAD_PULLSECRET
SSH_KEY
