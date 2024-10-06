[![Publish](https://github.com/FriendsOfREDAXO/docker-redaxo/actions/workflows/publish.yml/badge.svg)](https://github.com/FriendsOfREDAXO/docker-redaxo/actions/workflows/publish.yml)

# Docker image for REDAXO

This image for [REDAXO](https://github.com/redaxo/redaxo/) CMS is developed and maintained by [Friends Of REDAXO](https://github.com/FriendsOfREDAXO).

![Screenshot](https://raw.githubusercontent.com/friendsofredaxo/docker-redaxo/assets/redaxo_02.webp)

It is published both on [Docker Hub](https://hub.docker.com/r/friendsofredaxo/redaxo) and on [GitHub Container Registry](https://github.com/FriendsOfREDAXO/docker-redaxo/pkgs/container/redaxo), so you can choose between:

- `friendsofredaxo/redaxo`
- `ghcr.io/friendsofredaxo/redaxo`


## Supported tags

We provide two image variants:

- **Stable:** `5-stable`, `5`  
  Contains the latest stable REDAXO 5.x version and the lowest PHP version with [active support](https://www.php.net/supported-versions.php).
- **Edge:** `5-edge`  
  Contains the latest REDAXO 5.x, even beta versions, and the latest PHP, even RC versions.  
  Use this image for development and testing.

If you’re not sure, you probably want to go for `friendsofredaxo/redaxo:5` 🚀


## Environment variables

🤖 **REDAXO is auto-installed** within the container if the web root is empty and all required environment variables are provided.

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
* **`REDAXO_DB_CHARSET`**: `utf8mb4` charset is recommended for full emoji support 🙋 but requires at least MySQL 5.7.7 or MariaDB 10.2! Use `utf8` with older database systems.

Admin user to be created:

* **`REDAXO_ADMIN_USER`**
* **`REDAXO_ADMIN_PASSWORD`**: must comply with the password policy (requires at least 8 chars)

(See examples for `docker run` and `docker-compose` below)


## Usage

Note that we use `friendsofredaxo/redaxo:5` for the code examples.

### With [`docker run`](https://docs.docker.com/engine/reference/run/)

Remember that REDAXO requires a [MySQL](https://hub.docker.com/_/mysql) or [MariaDB](https://hub.docker.com/_/mariadb) database. Could be either an external server or another Docker container.

```bash
$ docker run \
    --name my-redaxo-project \
    -d \
    -p 80:80 \
    -e REDAXO_SERVER='http://localhost' \
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

Example for REDAXO container with MariaDB container:

```yml
services:

  redaxo:
    image: friendsofredaxo/redaxo:5
    ports:
      - 80:80
    volumes:
      - redaxo:/var/www/html
    environment:
      REDAXO_SERVER: http://localhost
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
    image: mariadb:10.11
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

🧁 See [recipes](https://github.com/FriendsOfREDAXO/docker-redaxo/tree/main/recipes) section for further examples!


## Need help?

If you have questions or need help, feel free to contact us in __Slack Chat__! You will receive an invitation here: [https://redaxo.org/slack/](https://redaxo.org/slack/)
