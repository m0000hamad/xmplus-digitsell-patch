<?php
/*
 * Cron entry point for granting time-plan purchases.
 *
 * The console command list lives in the encoded bootstrap, so this job cannot
 * be registered as an `xmplus` subcommand; TaskCommand schedules this file
 * directly, the same way it does bin/commissions.php.
 */
require __DIR__ . '/console.php';

$granted = (new \App\Jobs\TimePlanJob)->dispatch();

if ($granted > 0) {
    echo date('Y-m-d H:i:s') . " granted {$granted} time-plan order(s)" . PHP_EOL;
}
