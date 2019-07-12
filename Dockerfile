ARG         ALPINE_VERSION="${ALPINE_VERSION:-3.10}"
FROM        alpine:"${ALPINE_VERSION}"

LABEL       maintainer="https://github.com/hermsi1337"

ARG         OPENSSH_VERSION="${OPENSSH_VERSION:-7.9_p1-r5}"
ENV         CONF_VOLUME="/conf.d"
ENV         OPENSSH_VERSION="${OPENSSH_VERSION}" \
            CACHED_SSH_DIRECTORY="${CONF_VOLUME}/ssh" \
            AUTHORIZED_KEYS_VOLUME="${CONF_VOLUME}/authorized_keys" \
            ROOT_KEYPAIR_LOGIN_ENABLED="false" \
            ROOT_LOGIN_UNLOCKED="false" \
            USER_LOGIN_SHELL="/bin/bash" \
            USER_LOGIN_SHELL_FALLBACK="/bin/ash"

RUN         apk add --upgrade --no-cache \
                    bash \
                    bash-completion \
                    rsync \
                    openssh=${OPENSSH_VERSION} \
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
