#!/bin/bash
set -euo pipefail

# make sure web root is empty
if [[ ! -e "${PWD}" ]]; then
    echo >&2 "❌ ${PWD} is not empty! Skip REDAXO setup."
    exit 1
fi

echo >&2 "👉 Prepare REDAXO setup..."

# copy REDAXO to web root
cp -Rp /usr/src/redaxo/. ./ && \
    echo >&2 "✅ REDAXO has been successfully copied to ${PWD}."

# copy default config
mkdir -p redaxo/data/core/ && \
    cp -fp redaxo/src/core/default.config.yml redaxo/data/core/config.yml && \
    echo >&2 "✅ Default configuration has been successfully copied."

# set database connection
if php redaxo/bin/console -q db:set-connection \
    --host=$REDAXO_DB_HOST \
    --database=$REDAXO_DB_NAME \
    --login=$REDAXO_DB_USER \
    --password=$REDAXO_DB_PASSWORD 2> /dev/null || false; then
    echo >&2 "✅ Database connection has been configured."
else
    echo >&2 "❌ Failed to configure database."
    exit 1
fi

# prepare database
# run 'setup:check' for PHP version, directory permissions and database connection
# remember the docker database container takes some time to init!
echo >&2 "👉 Prepare database..."
repeat=10
while ! php redaxo/bin/console -q setup:check 2> /dev/null || false; do
    if [[ repeat -eq 0 ]]; then
        echo >&2 "❌ Failed to connect database."
        exit 1
    fi
    repeat=$((repeat - 1))
    sleep 5
    echo >&2 "⏳ Wait for database connection... ($repeat)"
done
echo >&2 "✅ Database has been has been successfully connected."

# init db
# TODO

# create admin user
# set database connection
if php redaxo/bin/console -q user:create \
    --admin \
    $REDAXO_USER \
    $REDAXO_PASSWORD 2> /dev/null || false; then
    echo >&2 "✅ Admin user successfully created."
else
    echo >&2 "✋ Could not create admin user!"
fi

# update config to disable setup mode
# TODO: use `config:set` once implemented into REDAXO cli
sed -ri \
    -e 's!setup: true!setup: false!g' \
    "redaxo/data/core/config.yml" && \
    echo >&2 "✅ Finished configuration."

# done!
echo >&2 "🚀 REDAXO setup successful."
echo >&2 " "

# execute CMD
exec "$@"
