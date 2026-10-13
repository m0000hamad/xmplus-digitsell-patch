<?php
/*
 * Cron entry point for plan reservations: links the paid reserve orders and
 * starts each subscription once the current plan has ended (or the chosen date
 * has come).
 *
 * The console command list lives in the encoded bootstrap, so this job cannot
 * be registered as an `xmplus` subcommand; TaskCommand schedules this file
 * directly, the same way it does bin/timeplans.php.
 */
require __DIR__ . '/console.php';

$report = (new \App\Jobs\ReserveJob)->dispatch();

if ($report['linked'] > 0 || $report['started'] > 0) {
    echo date('Y-m-d H:i:s') . sprintf(
        " reservations: %d linked, %d started", $report['linked'], $report['started']) . PHP_EOL;
}
