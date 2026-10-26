<?php
require __DIR__.'/console.php';
require_once __DIR__.'/../app/Patch/CheckoutFunds.php';
$pdo=\Illuminate\Database\Capsule\Manager::connection('default')->getPdo();
(new CheckoutFunds($pdo,true))->reconcileAll();
