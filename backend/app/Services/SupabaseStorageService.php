<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\UploadedFile;

class SupabaseStorageService
{
    protected ?string $url;
    protected ?string $key;
    protected string $bucket;

    public function __construct()
    {
        $this->url = rtrim(config('services.supabase.url', env('SUPABASE_URL')), '/');
        $this->key = config('services.supabase.key', env('SUPABASE_ANON_KEY'));
        $this->bucket = config('services.supabase.bucket', env('SUPABASE_BUCKET', 'avatars'));
    }

    /**
     * Upload a file to Supabase Storage.
     *
     * @param UploadedFile $file
     * @param string $folder
     * @return string|null The public URL of the uploaded file, or null on failure.
     */
    public function upload(UploadedFile $file, string $folder = 'profile-images'): ?string
    {
        if (empty($this->url) || empty($this->key)) {
            Log::error('Supabase credentials not configured.');
            return null;
        }

        // Generate a unique filename
        $filename = $file->hashName();
        $path = $folder . '/' . $filename;

        $uploadUrl = "{$this->url}/storage/v1/object/{$this->bucket}/{$path}";

        try {
            $response = Http::withHeaders([
                'Authorization' => "Bearer {$this->key}",
                'apiKey' => $this->key,
                'Content-Type' => $file->getMimeType(),
            ])->withBody(
                file_get_contents($file->getRealPath()),
                $file->getMimeType()
            )->post($uploadUrl);

            if ($response->successful()) {
                // Return the public URL of the uploaded asset
                return "{$this->url}/storage/v1/object/public/{$this->bucket}/{$path}";
            }

            Log::error('Supabase upload failed: ' . $response->body() . ' URL: ' . $uploadUrl);
            return null;
        } catch (\Exception $e) {
            Log::error('Supabase upload exception: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Delete a file from Supabase Storage.
     *
     * @param string $publicUrl
     * @return bool
     */
    public function delete(string $publicUrl): bool
    {
        if (empty($this->url) || empty($this->key)) {
            return false;
        }

        // Extract the path from the public URL
        // Expected format: {url}/storage/v1/object/public/{bucket}/{path}
        $prefix = "{$this->url}/storage/v1/object/public/{$this->bucket}/";
        if (!str_starts_with($publicUrl, $prefix)) {
            return false;
        }

        $path = substr($publicUrl, strlen($prefix));
        $deleteUrl = "{$this->url}/storage/v1/object/{$this->bucket}/{$path}";

        try {
            $response = Http::withHeaders([
                'Authorization' => "Bearer {$this->key}",
                'apiKey' => $this->key,
            ])->delete($deleteUrl);

            return $response->successful();
        } catch (\Exception $e) {
            Log::error('Supabase delete exception: ' . $e->getMessage());
            return false;
        }
    }
}
