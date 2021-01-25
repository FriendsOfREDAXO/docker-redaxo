FROM php:7.2-apache

# install persistent PHP extensions (they won't get purged afterwards)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --quiet --no-install-recommends \
        ghostscript \
        unzip \
    ; \
    rm -rf /var/lib/apt/lists/*

# install PHP extensions
RUN set -ex; \
    \
    # mark packages as being manually installed
    # see https://manpages.debian.org/stretch/apt/apt-mark.8.en.html
    savedAptMark="$(apt-mark showmanual)"; \
    \
    # install via apt-get
    # see https://manpages.debian.org/stretch/apt/apt-get.8.en.html
    apt-get update; \
    apt-get install -y --quiet --no-install-recommends \
        libfreetype6-dev \
        libjpeg-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libpng-dev \
    ; \
    \
    # install and configure via docker-php-ext
    # see https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        intl \
        pdo_mysql \
        zip \
    # delete output (except errors)
    > /dev/null \
    ; \
    \
    # install imagick
    # use github version for now until release from https://pecl.php.net/get/imagick is ready for PHP 8
    mkdir -p /usr/src/php/ext/imagick; \
    curl -fsSL https://github.com/Imagick/imagick/archive/06116aa24b76edaf6b1693198f79e6c295eda8a9.tar.gz | tar xvz -C "/usr/src/php/ext/imagick" --strip 1; \
    docker-php-ext-install imagick; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    # see https://github.com/docker-library/wordpress/blob/master/Dockerfile-debian.template
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# enable OPcache
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# enable apache modules
RUN set -eux; \
    a2enmod expires headers rewrite

# create mount point for web root
VOLUME /var/www/html

# declare REDAXO version and checksum
ENV REDAXO_VERSION=5.11.2 REDAXO_SHA=44fca196316606b1a64ba34f873bfc886d3cbbb5

# fetch REDAXO, validate checksum and extract to tmp folder
RUN set -e; \
    curl -Ls -o redaxo.zip https://github.com/redaxo/redaxo/releases/download/${REDAXO_VERSION}/redaxo_${REDAXO_VERSION}.zip; \
    echo "${REDAXO_SHA} *redaxo.zip" | shasum -c -a 256; \
    unzip -oq redaxo.zip -d /usr/src/redaxo; \
    rm redaxo.zip; \
    chown -R www-data:www-data /usr/src/redaxo

# copy and run entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# run CMD
CMD ["apache2-foreground"]
