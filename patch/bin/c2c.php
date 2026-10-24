<?php
/*
 * Cron entry point for card-to-card payments: keeps waiting orders open, sends
 * the admin the approve/reject message, tells customers the outcome, closes the
 * Telegram buttons and expires requests nobody looked at.
 *
 * The console command list lives in the encoded bootstrap, so this job cannot
 * be registered as an `xmplus` subcommand; TaskCommand schedules this file
 * directly, the same way it does bin/reserve.php.
 */
require __DIR__ . '/console.php';

$report = (new \App\Jobs\Card2CardJob)->dispatch();

if ($report['admins'] > 0 || $report['users'] > 0 || $report['expired'] > 0 || $report['closed'] > 0) {
    echo date('Y-m-d H:i:s') . sprintf(
        ' card-to-card: %d admin message(s), %d customer message(s), %d expired, %d closed, %d waiting',
        $report['admins'], $report['users'], $report['expired'], $report['closed'], $report['left']) . PHP_EOL;
}
