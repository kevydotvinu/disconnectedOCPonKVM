# Start PXE container for OCP deployment

function STOP_PXE {
podman kill $(sudo podman ps -a | grep pxe | awk '{print $1}') 2> /dev/null
podman rm -f $(sudo podman ps -a | grep pxe | awk '{print $1}') 2> /dev/null
podman rm -f --storage pxe 2> /dev/null
}

function START_PXE {
podman run --detach \
           --privileged \
           --net host \
           --volume "$(pwd)/boot.ipxe:/var/lib/tftpboot/boot.ipxe" \
           --volume "$(pwd)/dnsmasq.conf.dhcpproxy:/etc/dnsmasq.conf" \
           --security-opt label=disable \
           --name pxe localhost/kevydotvinu/pxe \
           --interface virbr0
}
STOP_PXE
START_PXE
