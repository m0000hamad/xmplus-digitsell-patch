<?php
/*
 * The panel's link builders (app/Http/Schema) crash on xhttp nodes; put the
 * defaults in now, once, without waiting for the hourly check (bin/schemafix.php).
 * Nothing is recorded in the database; a file that cannot be written is tried
 * again by the hourly job.
 */
return static function (PDO $db): void {
    $root = defined('ROOT') ? ROOT : dirname(__DIR__);

    require_once $root . '/app/Patch/SchemaFix.php';

    schemafixRun($root);
};
