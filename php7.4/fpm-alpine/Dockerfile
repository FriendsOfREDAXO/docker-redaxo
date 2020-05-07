FROM php:7.4-fpm-alpine

# install persistent PHP extensions (they won't get purged afterwards)
RUN apk add --no-cache \
    bash \
    ghostscript \
    # add perl-utils to include shasum
    perl-utils \
    sed \
    unzip

# install PHP extensions
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        # add icu-dev to be able to install intl extension
        icu-dev \
        imagemagick-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
	; \
    \
    # install and configure via docker-php-ext
    # see https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        intl \
        opcache \
        pdo_mysql \
        zip \
    # delete output (except errors)
    > /dev/null \
    ; \
    \
    # install imagick
    pecl install imagick-3.4.4; \
    docker-php-ext-enable imagick; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .redaxo-phpexts-rundeps $runDeps; \
    apk del .build-deps

# enable OPcache
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini



# create mount point for web root
VOLUME /var/www/html

# declare REDAXO version and checksum
ENV REDAXO_VERSION=5.10.0 REDAXO_SHA=3027c9745d4bb62db51733995b901cdd6e4406a6

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
CMD ["php-fpm"]
