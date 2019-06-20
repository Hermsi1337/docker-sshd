## Make your OpenSSH fly on Alpine

### Overview
Use this Dockerfile / -image to start a slim and highly customizable sshd-server with `bash` and `rsync` installed.

### Regular builds, automagically
[![Build Status](https://travis-ci.com/Hermsi1337/docker-sshd.svg?branch=master)](https://travis-ci.com/Hermsi1337/docker-sshd)   
Thanks to [Travis-CI](https://travis-ci.com/) this image is pushed weekly and creates new [tags](https://hub.docker.com/r/hermsi/alpine-sshd/tags/) if there are new versions available.

### Tags
For recent tags check [Dockerhub](https://hub.docker.com/r/hermsi/alpine-sshd/tags/).

### Features
* `bash`-shell and `rsync` installed
* Default `.bashrc` from `ubuntu`
* Desired shell is configurable by --env
* En- or disable `root`-user by --env
  * Choose between keypar and password auth for `root`
  * Password for `root` is configurable by --env
* Additional ssh-users can be created by --env
  * Authentication for additional users is done by keypair
* Beautifully colored log output 

### Usage examples
#### Authentication as root by password
```bash
$ docker run --rm \
--publish=1337:22 \
--env ROOT_PASSWORD=MyRootPW123 \
hermsi/alpine-sshd
```

After the container is up you are able to ssh in it as root with the in --env provided password for "root"-user.
```bash
$ ssh root@mydomain.tld -p 1337
```

#### Authentication as root by ssh-keypair
```bash
$ docker run --rm \
--publish=1337:22 \
--env ROOT_KEYPAIR_LOGIN_ENABLED=true \
--volume /path/to/authorized_keys:/root/.ssh/authorized_keys \
hermsi/alpine-sshd
```

After the container is up you are able to ssh in it as root with a private-key which matches the provided public-key in authorized_keys for "root"-user.
```bash
$ ssh root@mydomain.tld -p 1337 -i /path/to/private_key
```

#### Authenticate as additional user by ssh-keypair
```bash
$ docker run --rm \
--publish=1337:22 \
--env SSH_USERS="hermsi:1000:1000" \
--volume /path/to/hermsi_public_key:/conf.d/authorized_keys/hermsi \
hermsi/alpine-sshd
```

After the container is up you are able to ssh in it as the given user with a private-key that matches the provided public-key in authorized_keys for your created user.
```bash
$ ssh mydomain.tld -l hermsi -p 1337 -i /path/to/hermsi_private_key
```

#### Create multiple, additional users with keypair
```bash
$ docker run --rm \
--publish=1337:22 \
--env SSH_USERS="hermsi:1000:1000,dennis:1001:1001" \
--volume /path/to/hermsi_public_key:/conf.d/authorized_keys/hermsi \
--volume /path/to/dennis_public_key:/conf.d/authorized_keys/dennis \
hermsi/alpine-sshd
```

After the container is up you are able to ssh in it as one of the given users with a private-key that matches the provided public-key in authorized_keys for your desired user.
```bash
$ ssh root@mydomain.tld -p 1337 -i /path/to/private_key
```

### Configuration
While beeing very slim and vanilla this image is still highly customizable.

#### Environment variables
| Variable | Possible Values | Default value | Explanation |
|:-----------------:|:-----------------:|:----------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------:|
| ROOT_LOGIN_UNLOCKED | 'true' or 'false' | 'false' | Whether to enable or disable login as 'root' user |
| ROOT_KEYPAIR_LOGIN_ENABLED | 'true' or 'false' | 'false' | Enable login as 'root' by keypair (implies `ROOT_LOGIN_UNLOCKED`). Must mount public-key into container: `/root/.ssh/authorized_keys` |
| ROOT_PASSWORD | any desired string | `undefined` | Set password for login as `root` (implies `ROOT_LOGIN_UNLOCKED`) |
| USER_LOGIN_SHELL | any existing shell | `/bin/bash` | Choose the desired default shell for all additional users. If the configured shell is not existent, a fallback to `/bin/ash` is applied |

### Extending this image
This image is designed to be as slim and vanilla as possible.   
If you need additional Tools like `git` , I definetly recommend to build your own image on top of `alpine-sshd`:
```Dockerfile
FROM  hermsi/alpine-sshd:latest

RUN   apk add --no-cache \
            git
```

### Use with docker-compose
I built this image in order to use it along with a nginx and fpm-php container for transferring files via sftp.
If you are interested in a Dockerfile which fulfills this need: [this way](https://github.com/Hermsi1337/docker-compose/blob/master/full_php_dev_stack/docker-compose.yml)
