<?php
/*
 * Cron entry point for the pay-as-you-go wallet: credits paid charges, bills
 * usage on balance, moves accounts between plan and wallet, sends notices.
 *
 * The console command list lives in the encoded bootstrap, so this job cannot
 * be registered as an `xmplus` subcommand; TaskCommand schedules this file
 * directly, the same way it does bin/commissions.php.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\PaygJob)->dispatch();
