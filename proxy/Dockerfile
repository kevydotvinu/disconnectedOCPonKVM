FROM docker.io/alpine
ADD ./entrypoint.sh /entrypoint.sh
RUN apk add --update squid && \
    rm -rf /var/cache/apk/* && \
    chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
