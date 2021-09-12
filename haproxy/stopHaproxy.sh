podman kill $(sudo podman ps -a | grep haproxy | awk '{print $1}')
podman rm -f $(sudo podman ps -a | grep haproxy | awk '{print $1}')
podman rm -f --storage haproxy
