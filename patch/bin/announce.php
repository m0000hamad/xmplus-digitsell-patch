<?php
/*
 * Cron entry point for the two announcement campaigns: broadcasts the notice
 * (c1) and the invite nudge (c2) to the channels each one has switched on.
 * See app/Jobs/AnnounceJob.php.
 *
 * The console command list lives in the encoded bootstrap, so TaskCommand
 * schedules this file directly, like bin/promos.php.
 */
require __DIR__ . '/console.php';

(new \App\Jobs\AnnounceJob)->dispatch();
