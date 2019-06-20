#!/usr/bin/env bash

set -e

# enable debug mode if desired
if [[ "${DEBUG}" == "true" ]]; then 
    set -x
fi

log() {
    LEVEL="${1}"
    TO_LOG="${2}"

    WHITE='\033[1;37m'
    YELLOW='\033[1;33m'
    RED='\033[1;31m'
    NO_COLOR='\033[0m'

    if [[ "${LEVEL}" == "warning" ]]; then
        LOG_LEVEL="${YELLOW}WARN${NO_COLOR}"
    elif [[ "${LEVEL}" == "error" ]]; then
        LOG_LEVEL="${RED}ERROR${NO_COLOR}"
    else
        LOG_LEVEL="${WHITE}INFO${NO_COLOR}"
        if [[ -z "${TO_LOG}" ]]; then
            TO_LOG="${1}"
        fi
    fi

    echo -e "[${LOG_LEVEL}] ${TO_LOG}"
}

ensure_mod() {
    FILE="${1}"
    MOD="${2}"
    U_ID="${3}"
    G_ID="${4}"

    chmod "${MOD}" "${FILE}"
    chown "${U_ID}"."${G_ID}" "${FILE}"
}

generate_passwd() {
    hexdump -e '"%02x"' -n 16 /dev/urandom
}

# ensure backward comaptibility for earlier versions of this image
if [[ -n "${KEYPAIR_LOGIN}" ]] && [[ "${KEYPAIR_LOGIN}" == "true" ]]; then
    ROOT_KEYPAIR_LOGIN_ENABLED="${KEYPAIR_LOGIN}"
fi
if [[ -n "${ROOT_PASSWORD}" ]]; then
    ROOT_LOGIN_UNLOCKED="true"
fi

# enable root login if keypair login is enabled
if [[ "${ROOT_KEYPAIR_LOGIN_ENABLED}" == "true" ]]; then
    ROOT_LOGIN_UNLOCKED="true"
fi

# initiate default sshd-config if there is none available
if [[ ! "$(ls -A /etc/ssh)" ]]; then
    cp -a "${CACHED_SSH_DIRECTORY}"/* /etc/ssh/.
fi
rm -rf "${CACHED_SSH_DIRECTORY}"

# generate host keys if not present
ssh-keygen -A 1>/dev/null

log "Applying configuration for 'root' user ..."

if [[ "${ROOT_LOGIN_UNLOCKED}" == "true" ]] ; then

    # generate random root password
    if [[ -z "${ROOT_PASSWORD}" ]]; then
        log "    generating random password for user 'root'"
        ROOT_PASSWORD="$(generate_passwd)"
    fi

    echo "root:${ROOT_PASSWORD}" | chpasswd &>/dev/null
    log "    password for user 'root' set"
    log "warning" "    user 'root' is now UNLOCKED"

    # set root login mode by password or keypair
    if [[ "${ROOT_KEYPAIR_LOGIN_ENABLED}" == "true" ]] && [[ -f "${HOME}/.ssh/authorized_keys" ]]; then
        sed -i "s/#PermitRootLogin.*/PermitRootLogin without-password/" /etc/ssh/sshd_config
        sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
        ensure_mod "${HOME}/.ssh/authorized_keys" "0600" "root" "root"
        log "    enabled login by keypair and disabled password-login for user 'root'"
    else
        sed -i "s/#PermitRootLogin.*/PermitRootLogin\ yes/" /etc/ssh/sshd_config
        log "    enabled login by password for user 'root'"
    fi

else

    sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
    log "    disabled login for user 'root'"
    log "    user 'root' is now LOCKED"

fi

printf "\n"

log "Applying configuration for additional users ..."

if [[ ! -x "${USER_LOGIN_SHELL}" ]]; then
    log "error" "    can not allocate desired shell '${USER_LOGIN_SHELL}', falling back to '${USER_LOGIN_SHELL_FALLBACK}' ..."
    USER_LOGIN_SHELL="${USER_LOGIN_SHELL_FALLBACK}"
fi

log "    desired shell is ${USER_LOGIN_SHELL}"


if [[ -n "${SSH_USERS}" ]]; then

    IFS=","
    for USER in ${SSH_USERS}; do

        log "    '${USER}'"

        USER_NAME="$(echo "${USER}" | cut -d ':' -f 1)"
        USER_UID="$(echo "${USER}" | cut -d ':' -f 2)"
        USER_GID="$(echo "${USER}" | cut -d ':' -f 3)"

        if [[ -z "${USER_NAME}" ]] || [[ -z "${USER_UID}" ]] || [[ -z "${USER_GID}" ]]; then
            log "error" "        skipping invalid data '${USER_NAME}' - UID: '${USER_UID}' GID: '${USER_GID}'"
            continue
        fi
    
        getent group "${USER_GID}" &>/dev/null || addgroup -g "${USER_GID}" "${USER_NAME}"
        getent passwd "${USER_NAME}" &>/dev/null || adduser -s "${USER_LOGIN_SHELL}" -D -u "${USER_UID}" -G "${USER_NAME}" "${USER_NAME}"
        passwd -u "${USER_NAME}" &>/dev/null
        mkdir -p "/home/${USER_NAME}/.ssh"

        log "        user '${USER_NAME}' created - UID: '${USER_UID}' GID: '${USER_GID}'"

        MOUNTED_AUTHORIZED_KEYS="${AUTHORIZED_KEYS_VOLUME}/${USER_NAME}"
        LOCAL_AUTHORIZED_KEYS="/home/${USER_NAME}/.ssh/authorized_keys"

        if [[ ! -e "${MOUNTED_AUTHORIZED_KEYS}" ]]; then
            log "warning" "        no SSH authorized_keys found for user '${USER_NAME}'"
        else
            cp "${MOUNTED_AUTHORIZED_KEYS}" "${LOCAL_AUTHORIZED_KEYS}"
            log "        copied ${MOUNTED_AUTHORIZED_KEYS} to ${LOCAL_AUTHORIZED_KEYS}"
            ensure_mod "${LOCAL_AUTHORIZED_KEYS}" "0600" "${USER_NAME}" "${USER_GID}"
            log "        set mod 0600 on ${LOCAL_AUTHORIZED_KEYS}"
        fi

        printf "\n"

    done
    unset IFS

else

    log "    no additional SSH-users set"

fi

echo ""

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e "$@"