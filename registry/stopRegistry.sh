podman kill $(podman ps -a | grep registry | awk '{print $1}') > /dev/null
podman rm -f $(podman ps -a | grep registry | awk '{print $1}') > /dev/null
