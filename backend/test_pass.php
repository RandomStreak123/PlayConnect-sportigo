<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\Hash;
use App\Models\User;

$user = User::where('email', 'eaglekgs@gmail.com')->first();
if ($user) {
    echo "Current Hash: {$user->password}\n";
    $check_12345678 = Hash::check('12345678', $user->password);
    echo "Does it match '12345678'?: " . ($check_12345678 ? "YES" : "NO") . "\n";
} else {
    echo "User not found\n";
}
