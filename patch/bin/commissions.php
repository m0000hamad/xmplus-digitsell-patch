<?php
/*
 * Cron entry point for the referral commission payout.
 *
 * The console command list lives in the encoded bootstrap, so this job cannot be
 * registered as an `xmplus` subcommand; TaskCommand schedules this file directly.
 */
require __DIR__ . '/console.php';

$paid = (new \App\Jobs\CommissionJob)->dispatch();

if ($paid > 0) {
    echo date('Y-m-d H:i:s') . " credited {$paid} commission row(s)" . PHP_EOL;
}
