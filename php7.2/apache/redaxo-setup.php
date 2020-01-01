#!/usr/bin/php
<?php

$REX = [];
$REX['REDAXO'] = true;
$REX['HTDOCS_PATH'] = './';
$REX['BACKEND_FOLDER'] = 'redaxo';

// bootstrap core
require 'redaxo/src/core/boot.php';

// bootstrap addons
include_once rex_path::core('packages.php');

// ----------------------------------------------------------------------------

// run in setup mode only!
if (rex::isSetup()) {
    $err = '';

    // connect to db (repeat if not ready yet)
    // remember the docker database container takes some time to init!
    $dbConnected = false;
    for ($i = 1, $max = 15; $i <= $max; ++$i) {
        $check = rex_setup::checkDb($config, false);
        if ($check == '') {
            $dbConnected = true;
            echo '✅ Established database connection. (' . $i . ')', PHP_EOL;
            break;
        }
        sleep(4);
    }
    if (!$dbConnected) {
        echo '✋ Failed to connect database! Skip setup.';
        exit(1);
    }

    // init db
    $empty = rex_setup_importer::verifyDbSchema();
    if (!$empty) {
        echo '✋ Database not empty! Skip setup.';
        exit(1);
    }

    $err .= rex_setup_importer::prepareEmptyDb();
    $err .= rex_setup_importer::verifyDbSchema();

    if ($err != '') {
        echo $err;
        exit(1);
    }
}
