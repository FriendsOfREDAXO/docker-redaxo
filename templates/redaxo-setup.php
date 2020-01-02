#!/usr/bin/php
<?php

// check for cli
if (PHP_SAPI !== 'cli') {
    echo '✋ This script must be executed via cli!', PHP_EOL;
    exit(1);
}

// get arguments from command line
$options = getopt('', array('user::', 'password::'));

// bootstrap REDAXO
$REX = [];
$REX['REDAXO'] = true;
$REX['HTDOCS_PATH'] = './';
$REX['BACKEND_FOLDER'] = 'redaxo';

// bootstrap core
require 'redaxo/src/core/boot.php';

// bootstrap addons
include_once rex_path::core('packages.php');

// ----------------------------------------------------------------------------

// check for setup mode
if (!rex::isSetup()) {
    echo '✋ REDAXO is currently not in setup mode!', PHP_EOL;
    exit(1);
}

$errors = '';

// connect to db (repeat if not ready yet)
// remember the docker database container takes some time to init!
$config = rex_file::getConfig(rex_path::coreData('config.yml'));
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
    echo '✋ Failed to connect database!', PHP_EOL;
    exit(1);
}

// init db
$empty = rex_setup_importer::verifyDbSchema();
if (!$empty) {
    echo '✋ Database not empty!', PHP_EOL;
    exit(1);
}

$errors .= rex_setup_importer::prepareEmptyDb();
$errors .= rex_setup_importer::verifyDbSchema();

if ($errors != '') {
    echo $errors;
    exit(1);
}

// create admin user
// hint: once implemented, we'll use cli command 'user:create' instead!
if ($options['user'] && $options['password']) {
    $user = rex_sql::factory();
    $user->setTable(rex::getTablePrefix() . 'user');
    $user->setValue('name', $options['user']);
    $user->setValue('login', $options['user']);
    $user->setValue('password', rex_backend_login::passwordHash($options['password']));
    $user->setValue('admin', 1);
    $user->addGlobalCreateFields('console');
    $user->addGlobalUpdateFields('console');
    $user->setValue('status', '1');
    try {
        $user->insert();
        echo '✅ Admin user successfully created.', PHP_EOL;
    } catch (rex_sql_exception $e) {
        echo '✋ Could not create admin user!', PHP_EOL;
    }
}
else {
    echo '✋ No user data given. Skip creating user.', PHP_EOL;
}
