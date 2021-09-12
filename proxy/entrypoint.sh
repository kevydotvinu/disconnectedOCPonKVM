#!/bin/sh
/usr/sbin/squid -f /etc/squid/squid.conf
tail -f /dev/null
