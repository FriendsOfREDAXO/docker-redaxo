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
    "--db-createdb=no"
    "--db-setup=normal"
  );
  [[ -n "$REDAXO_LANG" ]] && setupArgs+=("--lang=${REDAXO_LANG}");
  [[ -n "$REDAXO_SERVER" ]] && setupArgs+=("--server=${REDAXO_SERVER}");
  [[ -n "$REDAXO_SERVERNAME" ]] && setupArgs+=("--servername=${REDAXO_SERVERNAME}");
  [[ -n "$REDAXO_ERROR_EMAIL" ]] && setupArgs+=("--error-email=${REDAXO_ERROR_EMAIL}");
  [[ -n "$REDAXO_TIMEZONE" ]] && setupArgs+=("--timezone=${REDAXO_TIMEZONE}");
  [[ -n "$REDAXO_DB_CHARSET" ]] && setupArgs+=("--db-charset=${REDAXO_DB_CHARSET}");
  [[ -n "$REDAXO_DB_PASSWORD" ]] && setupArgs+=("--db-password=${REDAXO_DB_PASSWORD}");
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

  # update file owner and group of writable folders (cache, data)
  chown -R www-data:www-data redaxo/cache redaxo/data;

  # done!
  echo >&2 " "
  echo >&2 "🚀 REDAXO setup successful."
  echo >&2 " "

  # install addons (if specified)
  if [[ -n ${REDAXO_ADDONS} ]] ; then
      echo >&2 "👉 Installing addons..."
      IFS=' ' read -r -a addons <<< "${REDAXO_ADDONS}"

      for addon in "${addons[@]}"
      do
          echo >&2 "👉 Installing addon ${addon}..."
          IFS='|' read -r -a addoninfo <<< "${addon}"
          if echo "${addoninfo[1]}" | grep "^http" &> /dev/null; then
              curl -s -L "${addoninfo[1]}" -o /tmp/tmp.zip
              cd redaxo/src/addons &>/dev/null
              unzip /tmp/tmp.zip &>/dev/null
              mv ${addoninfo[0]}* "${addoninfo[0]}"
              cd - &>/dev/null
          else
              php redaxo/bin/console install:download "${addoninfo[0]}" "${addoninfo[1]}"
          fi
          php redaxo/bin/console package:install "${addoninfo[0]}"
      done
  fi

  # run custom setup (if available)
  # hint: enables child images to extend the setup process
  CUSTOM_SETUP="/usr/local/bin/custom-setup.sh";
  if [[ -x "$CUSTOM_SETUP" ]]; then
    echo >&2 "👉 Run custom setup..."

    if "$CUSTOM_SETUP"; then
      echo >&2 " "
      echo >&2 "🚀 Custom setup successful."
      echo >&2 " "
    else
      echo >&2 " "
      echo >&2 "❌ Custom setup failed."
      echo >&2 " "
      exit 1
    fi
  fi
fi

# execute CMD
exec "$@"
