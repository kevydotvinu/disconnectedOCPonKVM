# Stops PXE container

function STOP_PXE {
	podman kill $(sudo podman ps -a | grep pxe | awk '{print $1}')
	podman rm -f $(sudo podman ps -a | grep pxe | awk '{print $1}')
	podman rm -f --storage pxe
}

STOP_PXE
