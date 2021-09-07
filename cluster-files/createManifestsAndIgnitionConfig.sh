#!/bin/bash
# Create Kubernetes manifests and ignition-configs

function CREATE_MANIFESTS {
../downloads/openshift-install create manifests --dir=./
}

function CREATE_IGNITIONS {
../downloads/openshift-install create ignition-configs --dir=./
}

CREATE_MANIFESTS
CREATE_IGNITIONS
