#!/bin/bash
# Configure host for OCP cluster deployment

function CHECK_PACKAGES {
# Check and install required packages
subscription-manager register
subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-ose-4.7-rpms
yum groupinstall -y virtualization-client virtualization-platform virtualization-tools
yum install -y screen podman httpd-tools jq git openshift-ansible
}

function CONFIGURE_DNS {
	systemctl enable NetworkManager --now
	rm -fv /etc/NetworkManager/conf.d/nm-dns.conf
	echo -e "[main]\ndns=dnsmasq" > /etc/NetworkManager/conf.d/nm-dns.conf
	rm -fv /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
	echo "local=/${CLUSTER_NAME}.${DOMAIN}/" > /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
	echo "address=/.apps.${CLUSTER_NAME}.${DOMAIN}/192.168.122.1" >> /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
	sed -i '/192.168.122.90/d' /etc/hosts
	sed -i '/192.168.122.91/d' /etc/hosts
	sed -i '/192.168.122.92/d' /etc/hosts
	sed -i '/192.168.122.93/d' /etc/hosts
	sed -i '/192.168.122.94/d' /etc/hosts
	sed -i '/192.168.122.95/d' /etc/hosts
	sed -i '/192.168.122.96/d' /etc/hosts
	sed -i '/192.168.122.97/d' /etc/hosts
	sed -i '/192.168.122.1/d' /etc/hosts
	echo "192.168.122.90 bootstrap.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.91 master0.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.92 master1.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.93 master2.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.94 worker0.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.95 worker1.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.96 worker2.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.97 rhel8.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	echo "192.168.122.1 lb.${CLUSTER_NAME}.${DOMAIN}" "api.${CLUSTER_NAME}.${DOMAIN}" "api-int.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	systemctl reload NetworkManager
	systemctl restart libvirtd
}

function CONFIGURE_WEBSERVER {
	screen -X -S webserver quit 2> /dev/null
	screen -S webserver -dm bash -c "cd $(pwd); python -m SimpleHTTPServer 8080"
	}

function CONFIGURE_DHCP {
	MAC=$(ip a s $(virsh net-info default | awk '/Bridge:/{print $2}') | awk '/ether /{print $2}' | cut -f1-4 -d':')
	MAC_BOOTSTRAP=$MAC:91:90
	MAC_MASTER0=$MAC:91:91
	MAC_MASTER1=$MAC:91:92
	MAC_MASTER2=$MAC:91:93
	MAC_WORKER0=$MAC:91:94
	MAC_WORKER1=$MAC:91:95
	MAC_WORKER2a=$MAC:91:96
	MAC_WORKER2b=$MAC:91:97
	MAC_RHEL8=$MAC:91:98
	virsh net-destroy default
	virsh net-start default
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_BOOTSTRAP}' name='bootstrap.ocp.example.local' ip='192.168.122.90'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_BOOTSTRAP}' name='bootstrap.ocp.example.local' ip='192.168.122.90'/>" --live --config
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_MASTER0}' name='master0.ocp.example.local' ip='192.168.122.91'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_MASTER0}' name='master0.ocp.example.local' ip='192.168.122.91'/>" --live --config
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_MASTER1}' name='master1.ocp.example.local' ip='192.168.122.92'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_MASTER1}' name='master1.ocp.example.local' ip='192.168.122.92'/>" --live --config
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_MASTER2}' name='master2.ocp.example.local' ip='192.168.122.93'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_MASTER2}' name='master2.ocp.example.local' ip='192.168.122.93'/>" --live --config
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER0}' name='worker0.ocp.example.local' ip='192.168.122.94'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER0}' name='worker0.ocp.example.local' ip='192.168.122.94'/>" --live --config
        virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER1}' name='worker1.ocp.example.local' ip='192.168.122.95'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER1}' name='worker1.ocp.example.local' ip='192.168.122.95'/>" --live --config
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER2a}' name='worker2.ocp.example.local' ip='192.168.122.96'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER2a}' name='worker2.ocp.example.local' ip='192.168.122.96'/>" --live --config
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER2b}' name='worker2.ocp.example.local' ip='192.168.122.97'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER2b}' name='worker2.ocp.example.local' ip='192.168.122.97'/>" --live --config
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_RHEL8}' name='rhel8.ocp.example.local' ip='192.168.122.98'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_RHEL8}' name='rhel8.ocp.example.local' ip='192.168.122.98'/>" --live --config
	virsh net-destroy default
	virsh net-start default
}

function CONFIGURE_FIREWALL {
	CIDR=$(ip -4 a s $(virsh net-info default | awk '/Bridge:/{print $2}') | awk '/inet /{print $2}')
	ALL=0.0.0.0/0
	iptables -D INPUT -p tcp -m tcp --dport 8080 -s $CIDR -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 8080 -s $CIDR -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 3128 -s $CIDR -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 3128 -s $CIDR -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 5000 -s $CIDR -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 5000 -s $CIDR -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 6443 -s $ALL -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 6443 -s $ALL -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 22623 -s $CIDR -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 22623 -s $CIDR -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 443 -s $ALL -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 443 -s $ALL -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 80 -s $ALL -j ACCEPT 2> /dev/null
	iptables -I INPUT 1 -p tcp -m tcp --dport 80 -s $ALL -j ACCEPT
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE 2> /dev/null
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535 2> /dev/null
}

source $(pwd)/env

#CHECK_PACKAGES
#CONFIGURE_DNS
CONFIGURE_WEBSERVER
#CONFIGURE_DHCP
CONFIGURE_FIREWALL
