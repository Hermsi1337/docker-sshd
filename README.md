# hermsi/alpine-sshd

[![Build and Deploy](https://github.com/Hermsi1337/docker-sshd/actions/workflows/build-and-deploy.yaml/badge.svg)](https://github.com/Hermsi1337/docker-sshd/actions/workflows/build-and-deploy.yaml)
[![Docker Pulls](https://img.shields.io/docker/pulls/hermsi/alpine-sshd?style=flat-square&logo=docker)](https://hub.docker.com/r/hermsi/alpine-sshd/)
[![Docker Stars](https://img.shields.io/docker/stars/hermsi/alpine-sshd?style=flat-square&logo=docker)](https://hub.docker.com/r/hermsi/alpine-sshd/)
[![Image Size](https://img.shields.io/docker/image-size/hermsi/alpine-sshd/latest?style=flat-square&logo=docker)](https://hub.docker.com/r/hermsi/alpine-sshd/)
[![Donate](https://img.shields.io/badge/Donate-PayPal-yellow?style=flat-square&logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=T85UYT37P3YNJ&source=url)

Make your OpenSSH fly on Alpine.

A slim, highly configurable OpenSSH server (`sshd`) on Alpine Linux with `bash`, `bash-completion` and `rsync` preinstalled. Typical uses: an SSH/SFTP sidecar for exchanging files with other containers or volumes, an rsync endpoint, or a lightweight jump host. Everything is configured through environment variables at container start — no image rebuild needed.

Images are built for `linux/amd64` and `linux/arm64` and rebuilt weekly so they stay current with Alpine security updates.

## Quick start

### Log in as root with a password

```bash
docker run --rm \
  --publish 1337:22 \
  --env ROOT_PASSWORD=MyRootPW123 \
  hermsi/alpine-sshd
```

```bash
ssh root@mydomain.tld -p 1337
```

### Log in as root with an SSH key

```bash
docker run --rm \
  --publish 1337:22 \
  --env ROOT_KEYPAIR_LOGIN_ENABLED=true \
  --volume /path/to/authorized_keys:/root/.ssh/authorized_keys \
  hermsi/alpine-sshd
```

```bash
ssh root@mydomain.tld -p 1337 -i /path/to/private_key
```

In this mode password authentication for `root` is disabled entirely.

### Create additional users (key-based login)

Users are declared as comma-separated `name:uid:gid` triplets. Each user authenticates with the public key mounted at `/conf.d/authorized_keys/<username>`:

```bash
docker run --rm \
  --publish 1337:22 \
  --env SSH_USERS="hermsi:1000:1000,dennis:1001:1001" \
  --volume /path/to/hermsi.pub:/conf.d/authorized_keys/hermsi \
  --volume /path/to/dennis.pub:/conf.d/authorized_keys/dennis \
  hermsi/alpine-sshd
```

```bash
ssh mydomain.tld -l hermsi -p 1337 -i /path/to/hermsi_private_key
```

Additional users authenticate by keypair only. The `root` account stays locked unless you explicitly unlock it (see below).

## Tags

The tag set encodes the exact OpenSSH package version and the Alpine release the image was built from:

| Tag pattern | Example | Description |
| --- | --- | --- |
| `latest` | `latest` | Most recent build |
| `<ssh-version>` | `10.3_p1-r0` | Exact Alpine `openssh` package version |
| `<ssh-version>-alpine` | `10.3_p1-r0-alpine` | Same, with explicit distro marker |
| `<ssh-version>-alpine<alpine-version>` | `10.3_p1-r0-alpine3.24` | Fully pinned: OpenSSH version and Alpine release |

Versions are detected automatically at build time from the current `alpine:latest` image, so new OpenSSH releases are published as soon as Alpine ships them. Independent of version changes, all tags are rebuilt and re-pushed **every Monday at 02:00 UTC** with a fresh package index, so even a pinned tag receives Alpine security fixes. For the full list of available tags see [Docker Hub](https://hub.docker.com/r/hermsi/alpine-sshd/tags/).

## Registries

The same image is published to three registries:

```bash
docker pull hermsi/alpine-sshd:latest
docker pull quay.io/hermsi1337/alpine-sshd:latest
docker pull ghcr.io/hermsi1337/docker-sshd:latest
```

## Configuration

### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `ROOT_LOGIN_UNLOCKED` | `false` | Unlock the `root` account for SSH login. When unlocked without `ROOT_PASSWORD`, a random password is generated (and not printed), so set one explicitly if you want password login. |
| `ROOT_PASSWORD` | *(unset)* | Password for `root`. Setting it implies `ROOT_LOGIN_UNLOCKED=true`. |
| `ROOT_KEYPAIR_LOGIN_ENABLED` | `false` | Key-based login for `root` (implies `ROOT_LOGIN_UNLOCKED=true`, disables password authentication). Requires a public key mounted at `/root/.ssh/authorized_keys`. |
| `SSH_USERS` | *(unset)* | Comma-separated list of additional users as `name:uid:gid` (e.g. `hermsi:1000:1000,dennis:1001:1001`). Invalid entries are skipped; an existing GID reuses the existing group. |
| `USER_LOGIN_SHELL` | `/bin/bash` | Login shell for additional users. If the configured shell is not executable, the fallback is used. |
| `USER_LOGIN_SHELL_FALLBACK` | `/bin/ash` | Fallback shell if `USER_LOGIN_SHELL` cannot be used. |
| `DEBUG` | *(unset)* | Set to `true` to trace the entrypoint (`set -x`) for troubleshooting. |
| `KEYPAIR_LOGIN` | *(unset)* | Deprecated alias for `ROOT_KEYPAIR_LOGIN_ENABLED`, kept for backward compatibility. |

### Ports, volumes and paths

| Path / Port | Purpose |
| --- | --- |
| `22/tcp` | sshd listens here — publish it to any host port you like. |
| `/etc/ssh` (volume) | sshd configuration and host keys. On first start with an empty volume, the stock configuration is restored and host keys are generated. Mount a volume here to keep host keys stable across container re-creations (avoids "host key changed" warnings). |
| `/root/.ssh/authorized_keys` | Public key(s) for `root` when `ROOT_KEYPAIR_LOGIN_ENABLED=true`. |
| `/conf.d/authorized_keys/<username>` | Public key(s) for each user listed in `SSH_USERS`. |

### Passing extra options to sshd

Arguments appended after the image name are handed straight to `sshd` (it runs in the foreground with `-D -e`):

```bash
docker run --rm --publish 1337:22 --env ROOT_PASSWORD=secret \
  hermsi/alpine-sshd -o LogLevel=VERBOSE
```

## Docker Compose example

```yaml
services:
  sshd:
    image: hermsi/alpine-sshd:latest
    ports:
      - "1337:22"
    environment:
      SSH_USERS: "hermsi:1000:1000"
    volumes:
      - ./keys/hermsi.pub:/conf.d/authorized_keys/hermsi:ro
      - ssh_host_config:/etc/ssh
    restart: unless-stopped

volumes:
  ssh_host_config:
```

## Supported architectures

`linux/amd64` and `linux/arm64` — published as a single multi-arch manifest, so `docker pull` automatically selects the right variant for your platform.

## Extending this image

The image is intentionally slim and vanilla. If you need extra tools such as `git`, build your own image on top:

```Dockerfile
FROM hermsi/alpine-sshd:latest

RUN  apk add --no-cache \
        git
```

## Contributing and maintenance

Development, CI/CD internals (build pipeline, version detection, release invariants) and common maintenance tasks are documented in [AGENTS.md](AGENTS.md). Pull requests trigger a full multi-arch build for validation, but nothing is pushed to the registries until the change lands on `master`.

## License

[MIT](LICENSE)
