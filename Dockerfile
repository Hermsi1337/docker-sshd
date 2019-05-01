ARG         ALPINE_VERSION=${ALPINE_VERSION:-3.9}
FROM        alpine:${ALPINE_VERSION}

LABEL       maintainer="https://github.com/hermsi1337"

ARG         OPENSSH_VERSION=${OPENSSH_VERSION:-7.9_p1-r5}
ENV         OPENSSH_VERSION=${OPENSSH_VERSION} \
            ROOT_PASSWORD=root \
            KEYPAIR_LOGIN=false

COPY        entrypoint.sh /
RUN         apk add --upgrade --no-cache openssh=${OPENSSH_VERSION} \
            && chmod +x /entrypoint.sh \
	    && mkdir -p /root/.ssh \
	    && rm -rf /var/cache/apk/* /tmp/*

EXPOSE      22
VOLUME      ["/etc/ssh"]
ENTRYPOINT  ["/entrypoint.sh"]
