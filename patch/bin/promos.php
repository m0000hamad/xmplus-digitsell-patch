<?php
/*
 * Cron entry point for promotions on subscription plans: logs promoted
 * purchases, applies prizes, closes finished promotions and restores list
 * prices. See app/Jobs/PromoJob.php.
 *
 * Scheduled directly from TaskCommand, like bin/timeplans.php - the console
 * command list lives in the encoded bootstrap.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\PromoJob)->dispatch();
