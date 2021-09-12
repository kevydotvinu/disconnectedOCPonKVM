# Create PXE container image for OCP deployment

function CREATE_PXE {
podman build . -t localhost/kevydotvinu/pxe
}

CREATE_PXE
