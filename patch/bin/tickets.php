<?php
require __DIR__ . '/console.php';
(new \App\Jobs\TicketJob)->dispatch();
