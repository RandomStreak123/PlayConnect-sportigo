<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$migrations = \DB::table('migrations')->get();
foreach ($migrations as $m) {
    echo "Migration: " . $m->migration . " (Batch: " . $m->batch . ")\n";
}
