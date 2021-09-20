FROM docker.io/alpine:3.7
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD openssl.cnf.add /etc/ssl/openssl.cnf.add
ADD conf/squid.conf /etc/squid/squid.conf
RUN apk add squid openssl ca-certificates && \
    chmod 755 /usr/local/bin/entrypoint.sh && \
    cat /etc/ssl/openssl.cnf.add >> /etc/ssl/openssl.cnf
EXPOSE 3128
EXPOSE 4128
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
