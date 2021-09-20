source $(dirname $(pwd))/env

if [ -z ${RELEASE} ]; then
echo "RELEASE is unset in" $(dirname $(pwd))/env "file!"; exit 1;
else echo "Using OpenShift" ${RELEASE} "release ..."
fi

OCP_RELEASE=${RELEASE}
LOCAL_REGISTRY='mirror.ocp.example.local:5000'
LOCAL_REPOSITORY='ocp4/openshift4'
PRODUCT_REPO='openshift-release-dev'
LOCAL_SECRET_JSON=$(dirname $(pwd))/downloads/pull-secret.json
RELEASE_NAME='ocp-release'
ARCHITECTURE='x86_64'
oc adm release mirror -a ${LOCAL_SECRET_JSON} --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run > dry-run.txt
oc adm release mirror -a ${LOCAL_SECRET_JSON} --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

OCP_RELEASE_NUMBER=${RELEASE}
DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE_NUMBER}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
DIGEST_ALGO="${DIGEST%%:*}"
DIGEST_ENCODED="${DIGEST#*:}"
SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)
cat >checksum-${OCP_RELEASE_NUMBER}.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE_NUMBER}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF
