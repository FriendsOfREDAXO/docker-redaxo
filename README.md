# Docker community image for REDAXO

There’s no official Docker image for REDAXO yet, but this one represents the __»official« community image__. It is developed and maintained by [Friends Of REDAXO](https://github.com/FriendsOfREDAXO).

## Supported tags

Tags follow this scheme: `REDAXO-PHP-Variant`.

* __REDAXO version__ can include major, feature or hotfix releases, such as: `5`, `5.8`, `5.8.1`.
* __PHP versions__: `php7.2`, `php7.3` _(default)_, `php7.4`
* __Variants__: `apache` _(default)_

As a __shorthand__, you can provide just the REDAXO version to use it with the default PHP version (7.3) and the default variant (Apache).

Examples:

* `5.8.1-php7.4-apache`
* `5` 🔥

A [complete list of tags](https://hub.docker.com/r/friendsofredaxo/redaxo/tags) is available at Docker Hub.

## Environment variables

Database credentials:

* `REDAXO_DB_HOST`
* `REDAXO_DB_NAME`
* `REDAXO_DB_USER`
* `REDAXO_DB_PASSWORD`

Admin user to be created:

* `REDAXO_USER`
* `REDAXO_PASSWORD`

## Usage

### With [`docker run`](https://docs.docker.com/engine/reference/run/)

Remember that REDAXO requires a [MySQL](https://hub.docker.com/_/mysql) or [MariaDB](https://hub.docker.com/_/mariadb) database. Could be either an external server or another Docker container.

```bash
$ docker run \
    --name my-redaxo-project \
    -d \
    -p 20080:80 \
    -e REDAXO_DB_HOST=db \
    -e REDAXO_DB_NAME=exampledb \
    -e REDAXO_DB_USER=exampleuser \
    -e REDAXO_DB_PASSWORD=examplepass \
    -e REDAXO_USER=admin \
    -e REDAXO_PASSWORD=admin123 \    
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
    environment:
      REDAXO_DB_HOST: db
      REDAXO_DB_NAME: exampledb
      REDAXO_DB_USER: exampleuser
      REDAXO_DB_PASSWORD: examplepass
      REDAXO_USER: admin
      REDAXO_PASSWORD: admin123
    volumes:
      - redaxo:/var/www/html

  db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'
    volumes:
      - db:/var/lib/mysql

volumes:
  redaxo:
  db:
```

## Need help?

If you have questions or need help, feel free to contact us in __Slack Chat__! You will receive an invitation here: [https://redaxo.org/slack/](https://redaxo.org/slack/)
