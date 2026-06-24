<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\SupabaseStorageService;
use Illuminate\Http\UploadedFile;

$service = new SupabaseStorageService();

// Create a temp file
$tempFile = tempnam(sys_get_temp_dir(), 'test_upload');
file_put_contents($tempFile, 'mock image content');

$file = new UploadedFile(
    $tempFile,
    'avatar.jpg',
    'image/jpeg',
    null,
    true // test mode
);

echo "Uploading mock file to Supabase..." . PHP_EOL;
$url = $service->upload($file);

if ($url) {
    echo "SUCCESS! Public URL: $url" . PHP_EOL;
} else {
    echo "FAILED to upload. Check logs/laravel.log for details." . PHP_EOL;
}

unlink($tempFile);
