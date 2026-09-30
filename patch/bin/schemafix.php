<?php
/*
 * Hourly check that the panel's link builders (app/Http/Schema) cannot crash on
 * an xhttp node - see app/Patch/SchemaFix.php. A panel update puts the original
 * files back; this puts the defaults in again within the hour.
 *
 * Scheduled from TaskCommand. Needs no database and no panel bootstrap. Writes
 * to its log only when it changed or failed to change something.
 */
require dirname(__DIR__) . '/app/Patch/SchemaFix.php';

foreach (schemafixRun(dirname(__DIR__)) as $file => $result) {
    if (strpos($result, 'patched (') === 0 || strpos($result, 'ERROR') === 0) {
        echo date('Y-m-d H:i:s') . ' ' . $file . ': ' . $result . "\n";
    }
}
