<?php
/*
 * Cron entry point for the OpenVPN server online / offline messages.
 *
 * Scheduled directly from TaskCommand, like bin/giftcards.php - the console
 * command list lives in the encoded bootstrap.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\OvpnJob)->dispatch();
