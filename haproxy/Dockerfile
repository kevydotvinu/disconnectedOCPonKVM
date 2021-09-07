FROM alpine

MAINTAINER Vinu K <vinu@gnulinuxmate.com>

RUN apk add --update haproxy && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["/usr/sbin/haproxy", "-f", "/etc/haproxy/haproxy.cfg"]
