## Make your OpenSSH fly on Alpine

### Overview
Use this Dockerfile / -image to start a sshd-server upon a lightweight Alpine container.

### Features
* Always installs the latest OpenSSH-Version available for Alpine
* Password of "root"-user can be changed when starting the container using --env
* You can choose between ssh-keypair- and password auth

### Extending this image
This image is designed to be as slim and vanilla as possible.   
If you need additional Tools like `git` or `bash`-shell, I definetly recommend to build your own image on top of `alpine-sshd`:
```Dockerfile
FROM  hermsi/alpine-sshd:latest

RUN   apk add --no-cache --upgrade \
            git \
            bash
```
### Basic Usage
#### Authentication by password
```
$ docker run --rm \
--publish=1337:22 \
--env ROOT_PASSWORD=MyRootPW123 \
hermsi/alpine-sshd
```

After the container is up you are able to ssh in it as root with the in --env provided password for "root"-user.
```
$ ssh root@mydomain.tld -p 1337
```
#### Authentication by ssh-keypair
```
$ docker run --rm \
--publish=1337:22 \
--env KEYPAIR_LOGIN=true \
--volume /path/to/authorized_keys:/root/.ssh/authorized_keys \
hermsi/alpine-sshd
```
After the container is up you are able to ssh in it as root with a private-key which matches the provided public-key in authorized_keys for "root"-user.
```
$ ssh root@mydomain.tld -p 1337 -i /path/to/private_key
```
### Use with docker-compose
I built this image in order to use it along with a nginx and fpm-php container for transferring files via sftp.
If you are interested in a Dockerfile which fulfills this need: [this way](https://github.com/Hermsi1337/docker-compose/blob/master/full_php_dev_stack/docker-compose.yml)
