## Make your OpenSSH fly on Alpine

### Overview

Docker container to provide a ready-to-go sshd-server for backintime.
Run this container on your backup target and no longer rely on the natively installed sshd-server and rsync.

This image is based on the work of [https://github.com/Hermsi1337/docker-sshd](https://github.com/Hermsi1337/docker-sshd).

### Tags

For recent tags check [Dockerhub](https://hub.docker.com/r/caco3x/backintime-sshd/tags/).

#### Docker Compose
See example in [docker-compose.yaml](docker-compose.yaml)


#### Environment variables

| Variable | Possible Values | Default value | Explanation |
|:-----------------:|:-----------------:|:----------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------:|
| USER_UID | any valid UID | `1009` | User ID for the backintime user (should match the target system) |
| USER_GID | any valid GID | `100` | Group ID for the backintime user (should match the target system) |
| PUBLIC_KEY | SSH public key string | `undefined` | SSH public key for backintime user authentication (required) |
