#!/bin/bash
# Create Kubernetes manifests and ignition-configs

function CLEAN_DIR {
	rm -rvf auth *.ign .openshift* metadata.json
}

function CREATE_MANIFESTS {
../downloads/openshift-install create manifests --dir=./
}

function CREATE_IGNITIONS {
../downloads/openshift-install create ignition-configs --dir=./
}

CLEAN_DIR
CREATE_MANIFESTS
CREATE_IGNITIONS
