<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

foreach (App\Models\User::all() as $u) {
    echo $u->id . ' - ' . $u->name . ' - ' . $u->username . ' - ' . $u->profile_picture . ' - ' . $u->profile_photo . PHP_EOL;
}
