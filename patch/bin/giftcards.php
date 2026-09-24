<?php
/*
 * Cron entry point for the gift card Telegram notice.
 *
 * Scheduled directly from TaskCommand, like bin/tgjoin.php - the console
 * command list lives in the encoded bootstrap.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\GiftCardNotifyJob)->dispatch();
