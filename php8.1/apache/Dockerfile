FROM php:8.1-apache

# install persistent PHP extensions (they won't get purged afterwards)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --quiet --no-install-recommends \
        ghostscript \
        locales \
        unzip \
    ; \
    rm -rf /var/lib/apt/lists/*

# generate locales
RUN set -eux; \
    echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "nl_NL.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen; \
    echo "sv_SE.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen

# install PHP extensions
RUN set -ex; \
    \
    # mark packages as being manually installed
    # see https://manpages.debian.org/stretch/apt/apt-mark.8.en.html
    apt-mark showmanual > /root/apt_mark_manual; \
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
        libwebp-dev \
        libzip-dev \
    ;

# enable apache modules
RUN set -eux; \
    a2enmod expires headers rewrite

RUN set -ex; \
    # install and configure via docker-php-ext
    # see https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j "$(nproc)" \
        exif \
        gd \
        intl \
        pdo_mysql \
        zip \
    # delete output (except errors)
    > /dev/null \
    ; \
    \
    # install imagick
    # https://pecl.php.net/package/imagick
    pecl install imagick; \
        docker-php-ext-enable imagick; \
        rm -r /tmp/pear; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    # see https://github.com/docker-library/wordpress/blob/master/Dockerfile-debian.template
    apt-mark auto '.*' > /dev/null; \
    xargs apt-mark manual < /root/apt_mark_manual; \
    rm /root/apt_mark_manual; \
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

# create mount point for web root
VOLUME /var/www/html

# declare REDAXO version and checksum
ENV REDAXO_VERSION=5.13.2 REDAXO_SHA=52071115e29ee2b797b425c4e9d7e1721334dc73

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
