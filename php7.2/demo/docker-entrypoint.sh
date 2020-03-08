#!/bin/bash
set -euo pipefail

if [[ -n "$(ls -A)" ]]; then
    echo >&2 " "
    echo >&2 "❌ ${PWD} is not empty! Skip REDAXO setup."
    echo >&2 " "

else

    echo >&2 "👉 Start REDAXO setup..."

    # copy REDAXO to web root
    cp -Rp /usr/src/redaxo/. ./ && \
        echo >&2 "✅ REDAXO has been successfully copied to ${PWD}."

    # copy default config
    mkdir -p redaxo/data/core/ && \
        cp -fp redaxo/src/core/default.config.yml redaxo/data/core/config.yml && \
        echo >&2 "✅ Default configuration has been successfully copied."

    # prepare database
    # remember the docker database container takes some time to init!
    echo >&2 "👉 Prepare database..."
    repeat=10
    while ! php redaxo/bin/console -q db:set-connection \
        --host=$REDAXO_DB_HOST \
        --database=$REDAXO_DB_NAME \
        --login=$REDAXO_DB_LOGIN \
        --password=$REDAXO_DB_PASSWORD 2> /dev/null || false; do
        if [[ repeat -eq 0 ]]; then
            echo >&2 "❌ Failed to connect database."
            exit 1
        fi
        repeat=$((repeat - 1))
        sleep 5
        echo >&2 "⏳ Wait for database connection... ($repeat)"
    done
    echo >&2 "✅ Database has been has been successfully connected."

    # run REDAXO setup
    # hint: get options via `php redaxo/bin/console setup:run --help`
    echo >&2 "👉 Run setup..."
    setupArgs=(
        "--agree-license"
        "--db-createdb=no"
        "--db-setup=normal"
    );
    [[ -n "$REDAXO_LANG" ]] && setupArgs+=("--lang=${REDAXO_LANG}");
    [[ -n "$REDAXO_SERVER" ]] && setupArgs+=("--server=${REDAXO_SERVER}");
    [[ -n "$REDAXO_SERVERNAME" ]] && setupArgs+=("--servername=${REDAXO_SERVERNAME}");
    [[ -n "$REDAXO_ERROR_EMAIL" ]] && setupArgs+=("--error-email=${REDAXO_ERROR_EMAIL}");
    [[ -n "$REDAXO_TIMEZONE" ]] && setupArgs+=("--timezone=${REDAXO_TIMEZONE}");
    [[ -n "$REDAXO_DB_CHARSET" ]] && setupArgs+=("--db-charset=${REDAXO_DB_CHARSET}");
    [[ -n "$REDAXO_DB_PASSWORD" ]] && setupArgs+=("--db-password=${REDAXO_DB_PASSWORD}"); # required again!
    [[ -n "$REDAXO_ADMIN_USER" ]] && setupArgs+=("--admin-username=${REDAXO_ADMIN_USER}");
    [[ -n "$REDAXO_ADMIN_PASSWORD" ]] && setupArgs+=("--admin-password=${REDAXO_ADMIN_PASSWORD}");

    if php redaxo/bin/console setup:run -q -n "${setupArgs[@]}"; then
        echo >&2 "✅ REDAXO has been successfully installed."
    else
        echo >&2 " "
        echo >&2 "❌ REDAXO setup failed."
        echo >&2 " "
        exit 1
    fi

    # done!
    echo >&2 " "
    echo >&2 "🚀 REDAXO setup successful."
    echo >&2 " "

fi
# FROM DOCKERIMAGE

#    # fetch REDAXO, validate checksum and extract to tmp folder
#    RUN set -e; \
#    #    curl -Ls -o redaxo.zip https://github.com/redaxo/redaxo/releases/download/${REDAXO_VERSION}/redaxo_${REDAXO_VERSION}.zip; \
#    #    curl -Ls -o redaxo.zip https://github.com/redaxo/redaxo/archive/master.zip; \
#        curl -Ls -o redaxo.zip https://github.com/redaxo/redaxo/archive/rex-command-package-sync.zip; \
#    #    echo "${REDAXO_SHA} *redaxo.zip" | shasum -c -a 256; \
#        unzip -oq redaxo.zip -d /usr/src; \
#    #    mv /usr/src/redaxo-master /usr/src/redaxo; \
#        mv /usr/src/redaxo-rex-command-package-sync /usr/src/redaxo; \
#        cp -r /usr/src/redaxo/redaxo/src/core/assets /usr/src/redaxo/assets/core; \
#    rm redaxo.zip; \
#        chown -R www-data:www-data /usr/src/redaxo










echo >&2 "👉 Start REDAXO DEMO setup..."

#    curl -Ls -o demo.zip https://github.com/FriendsOfREDAXO/demo_community/archive/3.0.0.zip; \
curl -Ls -o demo.zip https://github.com/FriendsOfREDAXO/demo_community/archive/command.zip; \
unzip -oq demo.zip -d /tmp/demo_community; \
#    mv /tmp/demo_community/demo_community-3.0.0 ./redaxo/src/addons/demo_community; \
mv /tmp/demo_community/demo_community-command ./redaxo/src/addons/demo_community; \
rm demo.zip; \

chown -R www-data:www-data ./

ls -la redaxo/src/addons/demo_community

php redaxo/bin/console package:install demo_community
php redaxo/bin/console -q demo_community:install -y

php redaxo/bin/console package:install -r structure/content

chown -R www-data:www-data ./

echo >&2 "✅ REDAXO DEMO has been successfully installed."
# execute CMD
exec "$@"
