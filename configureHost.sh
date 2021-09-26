#!/bin/bash
# Configure host for OCP cluster deployment

function CHECK_PACKAGES {
# Check and install required packages
rpm -q --quiet libvirt screen podman httpd-tools jq git openshift-ansible
}

function CONFIGURE_DNS {
	systemctl enable NetworkManager --now
	rm -fv /etc/NetworkManager/conf.d/nm-dns.conf
	echo -e "[main]\ndns=dnsmasq" > /etc/NetworkManager/conf.d/nm-dns.conf
	rm -fv /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
#	echo "local=/${CLUSTER_NAME}.${DOMAIN}/" > /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
	echo "address=/.apps.${CLUSTER_NAME}.${DOMAIN}/192.168.122.1" >> /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
	echo "addn-hosts=/etc/hosts" >> /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
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
	echo "192.168.122.1 lb.${CLUSTER_NAME}.${DOMAIN}" "api.${CLUSTER_NAME}.${DOMAIN}" "api-int.${CLUSTER_NAME}.${DOMAIN}" "mirror.${CLUSTER_NAME}.${DOMAIN}" "proxy.${CLUSTER_NAME}.${DOMAIN}" >> /etc/hosts
	systemctl restart NetworkManager
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
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER2a}' name='worker2a.ocp.example.local' ip='192.168.122.96'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER2a}' name='worker2a.ocp.example.local' ip='192.168.122.96'/>" --live --config
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_WORKER2b}' name='worker2b.ocp.example.local' ip='192.168.122.97'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_WORKER2b}' name='worker2b.ocp.example.local' ip='192.168.122.97'/>" --live --config
	virsh net-update default delete ip-dhcp-host --xml "<host mac='${MAC_RHEL8}' name='rhel8.ocp.example.local' ip='192.168.122.98'/>" --live --config 2> /dev/null
        virsh net-update default add-last ip-dhcp-host --xml "<host mac='${MAC_RHEL8}' name='rhel8.ocp.example.local' ip='192.168.122.98'/>" --live --config
	virsh net-destroy default
	virsh net-start default
	systemctl restart libvirtd
}

function CONFIGURE_FIREWALL {
	CIDR=$(ip -4 a s $(virsh net-info default | awk '/Bridge:/{print $2}') | awk '/inet /{print $2}')
	ALL=0.0.0.0/0
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE 2> /dev/null
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535 2> /dev/null
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp -j MASQUERADE --to-ports 1024-65535 2> /dev/null
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
}

function USAGE {
        echo "Configure the host for Disconnected OpenShift cluster deployment"
        echo ""
        echo "This script helps you to check the required packages and configure the DNS, web server, DHCP and firewall services"
        echo ""
        echo "Usage:"
        echo "  bash $0 -s [all|dns|web-server|dhcp|firewall|vms-internet]"
        echo ""
        echo "Options"
        echo "  -s: Service to be configured. One of:"
        echo "      all (all except guest vms internet) | dns | web-server | dhcp | firewall | vms-internet"
}

function ALL {
	( CHECK_PACKAGES 1>/dev/null && echo "✔ Required packages are installed" ) || echo "✗ Error: Please install required packages mentioned in the README.md file"
	sleep 1s
	( CONFIGURE_DNS 1>/dev/null && echo "✔ DNS configured" ) || echo "✗ Error: DNS configuration failed"
	sleep 1s
	( CONFIGURE_WEBSERVER 1>/dev/null && echo "✔ Web server configured" ) || echo "✗ Error: Web server configuration failed"
	sleep 1s
	( CONFIGURE_DHCP 1>/dev/null && echo "✔ DHCP entries added" ) || echo "✗ Error: DHCP configuration failed"
	sleep 1s
	( CONFIGURE_FIREWALL 1>/dev/null && echo "✔ Firewall configured" ) || echo "✗ Error: Firewall configuration failed"
}

function DNS {
	( CONFIGURE_DNS 1>/dev/null && echo "✔ DNS configured" ) || echo "✗ Error: DNS configuration failed"
}

function WEB_SERVER {
	( CONFIGURE_WEBSERVER 1>/dev/null && echo "✔ Web server configured" ) || echo "✗ Error: Web server configuration failed"
}

function DHCP {
	( CONFIGURE_DHCP 1>/dev/null && echo "✔ DHCP entries added" ) || echo "✗ Error: DHCP configuration failed"
}

function FIREWALL {
	( CONFIGURE_FIREWALL 1>/dev/null && echo "✔ Firewall configured" ) || echo "✗ Error: Firewall configuration failed"
}

function VMS_INTERNET {
	( iptables -t nat -A POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE 1>/dev/null && echo "✔ Enabled internet for guest VMs" ) || echo "✗ Error: Firewall configuration failed"
}

source $(pwd)/env

while getopts ":s:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            if [[ "${s}" == "all" ]]; then
            	ALL
            elif [[ "${s}" == "dns" ]]; then
                DNS
            elif [[ "${s}" == "web-server" ]]; then
                WEB_SERVER
            elif [[ "${s}" == "dhcp" ]]; then
                DHCP
            elif [[ "${s}" == "firewall" ]]; then
                FIREWALL
            elif [[ "${s}" == "vms-internet" ]]; then
                VMS_INTERNET
            else
                USAGE
            fi
            ;;
        *)
            USAGE
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z "${s}" ]; then
    USAGE
fi
