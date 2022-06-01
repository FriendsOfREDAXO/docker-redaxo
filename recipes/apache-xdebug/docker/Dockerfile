FROM friendsofredaxo/redaxo:5 as base

# Install and activate xdebug from pecl
RUN set -ex; \
    pecl -q update-channels; \
    pecl -q install xdebug; \
    docker-php-ext-enable xdebug; \
    { \
        echo 'xdebug.mode = develop,debug'; \
        echo 'xdebug.start_with_request = trigger'; \
        echo 'xdebug.client_host = host.docker.internal'; \
    } > /usr/local/etc/php/conf.d/90-xdebug.ini; \
    rm -rf /tmp/pear;

# Remove overhead from previous layers by starting from scratch
FROM scratch
COPY --from=base / /
CMD ["apache2-foreground"]
