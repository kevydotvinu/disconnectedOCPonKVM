#!/bin/bash

function CONFIGURE_IMAGE_REGISTRY {
	cat ${ROOT_DIR}/registry/certs/ca.pem ${ROOT_DIR}/registry/certs/server.pem > $(pwd)/registry.pem
	oc create cm registry-ca --from-file=updateservice-registry=$(pwd)/registry.pem --from-file=mirror.${CLUSTER_NAME}.${DOMAIN}..5000=$(pwd)/registry.pem -n openshift-config
	oc patch --type=merge --patch='{"spec":{"additionalTrustedCA":{"name":"registry-ca"}}}' image.config.openshift.io/cluster
}

function INSTALL_UPDATE_SERVICE_OPERATOR {
cat << EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-update-service
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true" 
EOF

cat << EOF | oc -n openshift-update-service create -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: update-service-operator-group
spec:
  targetNamespaces:
  - openshift-update-service
EOF

cat << EOF | oc -n openshift-update-service create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: update-service-subscription
spec:
  channel: v1
  installPlanApproval: "Automatic"
  source: "redhat-operator-index" 
  sourceNamespace: "openshift-marketplace"
  name: "cincinnati-operator"
EOF
}

function CREATE_UPDATE_SERVICE {
cat << EOF > Dockerfile
FROM registry.access.redhat.com/ubi8/ubi:8.1
RUN curl -L -o cincinnati-graph-data.tar.gz https://github.com/openshift/cincinnati-graph-data/archive/master.tar.gz
CMD exec /bin/bash -c "tar xvzf cincinnati-graph-data.tar.gz -C /var/lib/cincinnati/graph-data/ --strip-components=1"
EOF
podman build -f ./Dockerfile -t mirror.${CLUSTER_NAME}.${DOMAIN}:5000/openshift/graph-data:latest
podman push --authfile ${ROOT_DIR}/downloads/pull-secret.json mirror.${CLUSTER_NAME}.${DOMAIN}:5000/openshift/graph-data:latest
NAME=update-service
RELEASE_IMAGES=mirror.${CLUSTER_NAME}.${DOMAIN}:5000/ocp4/openshift4-release-images
GRAPH_DATA_IMAGE=mirror.${CLUSTER_NAME}.${DOMAIN}:5000/openshift/graph-data:latest
oc -n openshift-update-service create -f - <<EOF
apiVersion: updateservice.operator.openshift.io/v1
kind: UpdateService
metadata:
  name: ${NAME}
spec:
  replicas: 2
  releases: ${RELEASE_IMAGES}
  graphDataImage: ${GRAPH_DATA_IMAGE}
EOF
}

function CONFIGURE_CVO {
	NAMESPACE=openshift-update-service
	NAME=update-service
	POLICY_ENGINE_GRAPH_URI=http://$(oc get route update-service-policy-engine-route -o jsonpath={'.spec.host'} -n openshift-update-service)/api/upgrades_info/v1/graph
	PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
	oc patch clusterversion version -p $PATCH --type merge
}

function CONFIGURE_ROUTE {
	oc patch route --type=merge --patch='{"spec":{"tls":{"insecureEdgeTerminationPolicy":"Allow"}}}' update-service-policy-engine-route -n openshift-update-service
}

KUBECONFIG=$(dirname $(dirname $(pwd)))/cluster-files/auth/kubeconfig
ROOT_DIR=$(dirname $(dirname $(pwd)))
CONFIGURE_IMAGE_REGISTRY
INSTALL_UPDATE_SERVICE_OPERATOR
CREATE_UPDATE_SERVICE
CONFIGURE_CVO
CONFIGURE_ROUTE
