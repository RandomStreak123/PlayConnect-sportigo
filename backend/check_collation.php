<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;

$columns = DB::select('SHOW FULL COLUMNS FROM users');
foreach ($columns as $column) {
    if (in_array($column->Field, ['username', 'email'])) {
        echo "Column: {$column->Field} | Type: {$column->Type} | Collation: {$column->Collation}\n";
    }
}
