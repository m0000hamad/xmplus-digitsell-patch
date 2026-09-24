<?php
/*
 * Cron entry point for the one-time Telegram channel gift.
 *
 * Scheduled directly from TaskCommand, like bin/timeplans.php - the console
 * command list lives in the encoded bootstrap.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\TgJoinJob)->dispatch();
