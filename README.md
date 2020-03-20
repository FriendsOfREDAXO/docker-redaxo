# Docker community image for REDAXO

There’s no official Docker image for REDAXO yet, but this one represents the __»official« community image__. It is developed and maintained by [Friends Of REDAXO](https://github.com/FriendsOfREDAXO).

![Screenshot](https://raw.githubusercontent.com/redaxo/redaxo/assets/redaxo_02.png)


## Supported tags

Tags follow this scheme: `REDAXO-PHP-Variant`.

* __REDAXO version__ can include major, feature or hotfix releases, such as: `5`, `5.9`, `5.9.0`.
* __PHP versions__: `php7.4` _(default)_, `php7.3`, `php7.2`
* __Variants__: `apache` _(default)_, `fpm`, `fpm-alpine`

As a __shorthand__, you can provide just the REDAXO version to use it with the default PHP version (7.4) and the default variant (Apache).

Examples:

* `5.9.0-php7.4-fpm`
* `5.9.0-php7.4-fpm-alpine`
* `5.9.0-php7.4-apache`
* `5.9-php7.4-apache`
* `5-php7.4-apache`
* `5` 🔥

A [complete list of tags](https://hub.docker.com/r/friendsofredaxo/redaxo/tags) is available at Docker Hub.


## Image variants

We provide 3 image variants:

* `apache` _(default)_  
  This image comes with an **Apache webserver included** and brings PHP with common extensions required to work with REDAXO out of the box. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.  
  If you are unsure about what your needs are, you probably want to use this one.
* `fpm`  
  This image doesn’t include a webserver and only starts a PHP FPM container. Use this image if you already have a **separate webserver** running, which is often NGINX.
* `fpm-alpine`  
  This image is based on [Alpine Linux](http://alpinelinux.org) and has a **very small footprint**. It doesn’t include a webserver and only starts a PHP FPM process. Use this image if you already have a separate webserver running and a small image size is very important.


## Environment variables

System settings:

* **`REDAXO_SERVER`**
* **`REDAXO_SERVERNAME`**
* **`REDAXO_ERROR_EMAIL`**
* **`REDAXO_LANG`**
* **`REDAXO_TIMEZONE`**

Database settings:

* **`REDAXO_DB_HOST`**
* **`REDAXO_DB_NAME`**
* **`REDAXO_DB_LOGIN`**
* **`REDAXO_DB_PASSWORD`**
* **`REDAXO_DB_CHARSET`**: `utf8mb4` charset is recommended for full emoji support 🙋 but requires at least MySQL 5.7.7 or MariaDB 10.2! Use `utf8` with older database systems :-(

Admin user to be created:

* **`REDAXO_ADMIN_USER`**
* **`REDAXO_ADMIN_PASSWORD`**: must comply with the password policy (requires at least 8 chars)

(See examples for `docker run` and `docker-compose` below)


## Usage

Note that we use `friendsofredaxo/redaxo:5` for the code examples, which represents the latest REDAXO 5 with Apache and PHP 7.4 as our current default version.

### With [`docker run`](https://docs.docker.com/engine/reference/run/)

Remember that REDAXO requires a [MySQL](https://hub.docker.com/_/mysql) or [MariaDB](https://hub.docker.com/_/mariadb) database. Could be either an external server or another Docker container.

_Hint: We recommend to use at least MySQL 5.7.7 or MariaDB 10.2 for full emoji support via utf8mb4 charset!_

```bash
$ docker run \
    --name my-redaxo-project \
    -d \
    -p 20080:80 \
    -e REDAXO_SERVER='http://localhost:20080' \
    -e REDAXO_SERVERNAME='My Website' \
    -e REDAXO_ERROR_EMAIL='john@doe.example' \
    -e REDAXO_LANG='en_gb' \
    -e REDAXO_TIMEZONE='Europe/London' \
    -e REDAXO_DB_HOST='db' \
    -e REDAXO_DB_NAME='redaxo' \
    -e REDAXO_DB_LOGIN='redaxo' \
    -e REDAXO_DB_PASSWORD='s3cretpasswOrd!' \
    -e REDAXO_DB_CHARSET='utf8mb4' \
    -e REDAXO_ADMIN_USER='admin' \
    -e REDAXO_ADMIN_PASSWORD='PunKisNOT!dead' \
    friendsofredaxo/redaxo:5
```

### With [`docker-compose`](https://docs.docker.com/compose/reference/overview/)

Example for REDAXO container with MySQL container:

```yml
version: '3'
services:

  redaxo:
    image: friendsofredaxo/redaxo:5
    ports:
      - 20080:80
    volumes:
      - redaxo:/var/www/html
    environment:
      REDAXO_SERVER: http://localhost:20080
      REDAXO_SERVERNAME: 'My Website'
      REDAXO_ERROR_EMAIL: john@doe.example
      REDAXO_LANG: en_gb
      REDAXO_TIMEZONE: Europe/London
      REDAXO_DB_HOST: db
      REDAXO_DB_NAME: redaxo
      REDAXO_DB_LOGIN: redaxo
      REDAXO_DB_PASSWORD: 's3cretpasswOrd!'
      REDAXO_DB_CHARSET: utf8mb4
      REDAXO_ADMIN_USER: admin
      REDAXO_ADMIN_PASSWORD: 'PunKisNOT!dead'

  db:
    image: mysql:8
    volumes:
      - db:/var/lib/mysql
    environment:
      MYSQL_DATABASE: redaxo
      MYSQL_USER: redaxo
      MYSQL_PASSWORD: 's3cretpasswOrd!'
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'

volumes:
  redaxo:
  db:
```

## Recipes

🧁 See [recipes](https://github.com/FriendsOfREDAXO/docker-redaxo/tree/master/recipes) section for further examples!


## Need help?

If you have questions or need help, feel free to contact us in __Slack Chat__! You will receive an invitation here: [https://redaxo.org/slack/](https://redaxo.org/slack/)
