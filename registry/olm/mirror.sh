#!/bin/bash

function GET_OPERATORS_LIST {
	echo "Removing old opm container ..."
	podman kill $(podman ps -a | grep rh-o-index | awk '{print $1}') > /dev/null
	podman rm -f $(podman ps -a | grep rh-o-index | awk '{print $1}') > /dev/null
	echo "Removing old grpcurl container ..."
	podman kill $(podman ps -a | grep grpcurl | awk '{print $1}') > /dev/null
	podman rm -f $(podman ps -a | grep grpcurl | awk '{print $1}') > /dev/null
	echo "Starting new opm container ..."
	podman run --net host --name rh-o-index -d registry.redhat.io/redhat/redhat-operator-index:v${RELEASE_MINOR}
	podman run --net host --name grpcurl fullstorydev/grpcurl:latest -plaintext localhost:50051 api.Registry/ListPackages > packages.out
	[ -s $(pwd)/packages.out ] || { echo "✗ The packages.out file is not generated"; exit 1; }
}

function OPERATOR_SELECTION {
	# Gather the Operators name into an array
	unset OPERATOR
	unset OPERATORS
	unset SELECTION
	while IFS= read -r LINE; do
	  OPERATORS+=("${LINE}")
	done < <(cat packages.out | jq -r .name)
	
	# Iterate over an array to create select menu
	select OPERATOR in "${OPERATORS[@]}" "done"; do
	  case ${OPERATOR} in
	    "done")
	      echo "✔ Operator selection done"
	      break
	      ;;
	    *[a-z]*)
	      echo "✔ The ${OPERATOR} has been selected and added to the list"
              SELECTION=${OPERATOR},${SELECTION}
              echo "Current list contains $( echo ${SELECTION} | sed 's/,$//g')"
	      ;;
	    *)
	      echo "Please enter the corresponding number for the Operator name"
	      ;;
	  esac
	done
	[ -n "${OPERATOR}" ] || { echo "✗ Operator name is not selected"; exit 1; }
}

function CREATE_INDEX_IMAGE {
	echo "Pruning index image ..."
	set -x && \
	podman exec -it rh-o-index cp /database/index.db /registry/index.db && \
	podman exec -it rh-o-index opm registry prune -p $( echo ${SELECTION} | sed 's/,$//g') --database /registry/index.db && \
	podman cp rh-o-index:/registry/index.db . && \
	podman cp index.db rh-o-index:/database/index.db && \
	podman commit rh-o-index mirror.ocp.example.local:5000/olm/redhat-operator-index:v${RELEASE_MINOR} && \
	podman push --authfile ${PULLSECRET} mirror.ocp.example.local:5000/olm/redhat-operator-index:v${RELEASE_MINOR} && \
	set +x
	[ $? == 0 ] || { echo "✗ The index image is not generated"; exit 1; }
}

function MIRROR_CATALOG {
	while true; do
	oc adm catalog mirror -a ${PULLSECRET} mirror.ocp.example.local:5000/olm/redhat-operator-index:v${RELEASE_MINOR} mirror.ocp.example.local:5000/olm --to-manifests=$(pwd)/manifests --index-filter-by-os='linux/amd64' 2>&1 | tee mirror-catalog.log
	if ! grep error mirror-catalog.log; then break; fi
	echo "✗ The Operator catalog mirroring is not completed"
	done
	echo "✔ The Operator catalog mirroring is completed"
}

source $(dirname $(dirname $(pwd)))/env
RELEASE_MINOR=$(echo ${RELEASE} | cut -d"." -f1-2)
PULLSECRET=$(dirname $(dirname $(pwd)))/downloads/pull-secret.json
GET_OPERATORS_LIST || exit 1
OPERATOR_SELECTION || exit 1
CREATE_INDEX_IMAGE || exit 1
MIRROR_CATALOG || exit 1
