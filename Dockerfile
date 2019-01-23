ARG         ALPINE_VERSION=${ALPINE_VERSION:-3.8}
FROM        alpine:${ALPINE_VERSION}

LABEL       maintainer="https://github.com/hermsi1337"

ARG         OPENSSH_VERSION=${OPENSSH_VERSION:-7.7_p1-r3}
ENV         OPENSSH_VERSION=${OPENSSH_VERSION} \
            ROOT_PASSWORD=root \
            KEYPAIR_LOGIN=false

ADD         entrypoint.sh /
RUN         apk add --upgrade --no-cache openssh=${OPENSSH_VERSION} \
            && chmod +x /entrypoint.sh \
	    && mkdir -p /root/.ssh \
	    && rm -rf /var/cache/apk/* /tmp/*

EXPOSE      22
VOLUME      ["/etc/ssh"]
ENTRYPOINT  ["/entrypoint.sh"]
