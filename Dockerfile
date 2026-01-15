ARG         ALPINE_VERSION="latest"
FROM        alpine:${ALPINE_VERSION}

LABEL       maintainer="https://github.com/caco3"

ENV         CONF_VOLUME="/conf.d"
ENV         CACHED_SSH_DIRECTORY="${CONF_VOLUME}/ssh" \
            AUTHORIZED_KEYS_VOLUME="${CONF_VOLUME}/authorized_keys" \
            ROOT_KEYPAIR_LOGIN_ENABLED="false" \
            ROOT_LOGIN_UNLOCKED="false" \
            USER_LOGIN_SHELL="/bin/bash" \
            USER_LOGIN_SHELL_FALLBACK="/bin/ash"

RUN         apk add --upgrade --no-cache \
                    bash \
                    rsync \
                    openssh \
                    fclones \
            && \
            mkdir -p /root/.ssh "${CONF_VOLUME}" "${AUTHORIZED_KEYS_VOLUME}" \
            && \
            cp -a /etc/ssh "${CACHED_SSH_DIRECTORY}" \
            && \
            rm -rf /var/cache/apk/*

COPY        entrypoint.sh /
COPY        conf.d/etc/ /etc/
EXPOSE      22
VOLUME      ["/etc/ssh"]
ENTRYPOINT  ["/entrypoint.sh"]
