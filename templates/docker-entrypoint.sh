#!/bin/bash
set -euo pipefail

# make sure web root is empty
if [[ ! -e "${PWD}" ]]; then
    echo >&2 "❌ ${PWD} is not empty! Skip REDAXO setup."
    exit 1
fi

echo >&2 "👉 Prepare REDAXO setup..."

# copy REDAXO to web root
cp -Rp /usr/src/redaxo/. ./
echo >&2 "✅ REDAXO has been successfully copied to ${PWD}."

# copy default config
mkdir -p redaxo/data/core/ && \
    cp -fp redaxo/src/core/default.config.yml redaxo/data/core/config.yml
echo >&2 "✅ Default configuration has been successfully copied."

# set database connection
if php redaxo/bin/console -q db:set-connection \
    --host=$REDAXO_DB_HOST \
    --database=$REDAXO_DB_NAME \
    --login=$REDAXO_DB_USER \
    --password=$REDAXO_DB_PASSWORD; then
    echo >&2 "✅ Database connection has been configured."
else
    echo >&2 "❌ Failed to configure database."
    exit 1
fi

# run setup (and clean up afterwards)
# hint: we make use of a setup helper file as long as the setup process is not yet
# available via console: https://github.com/redaxo/redaxo/issues/1114
echo >&2 "👉 Prepare database..."
if php redaxo-setup.php --user="$REDAXO_USER" --password="$REDAXO_PASSWORD"; then
    rm -f redaxo-setup.php
    echo >&2 "✅ Database has been successfully prepared."
else
    echo >&2 "❌ Failed to prepare database."
    exit 1
fi

# run setup check
# checks PHP version, directory permissions and database connection
if php redaxo/bin/console -q setup:check; then
    echo >&2 "✅ Setup check successful."
else
    echo >&2 "❌ Setup check failed."
    exit 1
fi

# update config to disable setup mode
sed -ri \
    -e 's!setup: true!setup: false!g' \
    "redaxo/data/core/config.yml"
echo >&2 "✅ Finished configuration."

# done!
echo >&2
echo >&2 "🚀 REDAXO setup successful."
echo >&2

# execute CMD
exec "$@"
