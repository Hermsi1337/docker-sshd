#!/bin/sh

if [ "${ROOT_PASSWORD}" == "root" ] || [ -z "${ROOT_PASSWORD}" ]; then
    export ROOT_PASSWORD="$(hexdump -e '"%02x"' -n 16 /dev/urandom)"
    echo "Successfully generated a random password for root"
fi

echo "root:${ROOT_PASSWORD}" | chpasswd

# generate host keys if not present
ssh-keygen -A

# set root login mode by password or keypair
if [ "${KEYPAIR_LOGIN}" = "true" ] && [ -f "${HOME}/.ssh/authorized_keys" ] ; then
    sed -i "s/#PermitRootLogin.*/PermitRootLogin without-password/" /etc/ssh/sshd_config
    sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
    chmod 600 "${HOME}/.ssh/authorized_keys"
    echo "Enabled root-login by keypair and disabled password-login"
else
    sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config
    echo "Enabled root-login by password"
fi

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e "$@"
