#!/bin/bash
set -euo pipefail

cd /var/www/html

php redaxo/bin/console install:download developer 3.9.2
php redaxo/bin/console package:install developer

php redaxo/bin/console install:download yform 4.2.1
php redaxo/bin/console package:install yform

php redaxo/bin/console install:download yrewrite 2.10.0
php redaxo/bin/console package:install yrewrite

php redaxo/bin/console install:download login_neon 1.0.0
php redaxo/bin/console package:install login_neon

chown -R www-data:www-data ./
