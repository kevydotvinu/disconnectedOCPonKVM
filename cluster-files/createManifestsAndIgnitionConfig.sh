#!/bin/bash
# Create Kubernetes manifests and ignition-configs

function CLEAN_DIR {
	echo "Removing old files..."
	rm -rvf auth *.ign .openshift* metadata.json
}

function CREATE_MANIFESTS {
	echo "Creating manifests..."
	$(dirname $(pwd))/downloads/openshift-install create manifests --dir=./
}

function CREATE_IGNITIONS {
	echo "Creating ignition-configs files..."
	$(dirname $(pwd))/downloads/openshift-install create ignition-configs --dir=./
}

CLEAN_DIR && echo "✔ Completed"
CREATE_MANIFESTS && echo "✔ Completed"
CREATE_IGNITIONS && echo "✔ Completed"
