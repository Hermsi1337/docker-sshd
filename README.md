## Make your OpenSSH fly on Alpine

### Overview
Use this Dockerfile / -image to start a sshd-server upon a lightweight Alpine container.

### Features
* Always installs the latest OpenSSH-Version available for Alpine
* Password of "root"-user can be changed when starting the container using --env

### Basic Usage
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

### Use with docker-compose
I built this image in order to use it along with a nginx and fpm-php container for transferring files via sftp.
If you are interested in a Dockerfile which fulfills this need: [this way](https://github.com/Hermsi1337/docker-compose/blob/master/full_php_dev_stack/docker-compose.yml)