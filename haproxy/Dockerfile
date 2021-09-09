FROM alpine

MAINTAINER Vinu K <vinu@gnulinuxmate.com>

RUN apk add --update haproxy && \
    rm -rf /var/cache/apk/*

ADD haproxy.cfg /etc/haproxy/haproxy.cfg

ENTRYPOINT ["/usr/sbin/haproxy", "-f", "/etc/haproxy/haproxy.cfg"]
