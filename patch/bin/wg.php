<?php
/*
 * Cron entry point for the WireGuard server online / offline messages.
 *
 * Scheduled directly from TaskCommand, like bin/ovpn.php - the console
 * command list lives in the encoded bootstrap.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\WgJob)->dispatch();