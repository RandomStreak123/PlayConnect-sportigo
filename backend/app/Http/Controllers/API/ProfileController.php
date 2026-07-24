<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use App\Models\User;

class ProfileController extends Controller
{
    public function uploadProfilePhoto(Request $request)
    {
        $request->validate([
            'profile_photo' => 'required|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        /** @var User $user */
        $user = auth()->user();

        // 1. Delete the old photo from Cloudinary if it exists
        if ($user->avatar) {
            $this->deleteFromCloudinary($user->avatar);
        }

        // 2. Upload the new photo to Cloudinary
        try {
            $path = $this->uploadToCloudinary($request->file('profile_photo'));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to upload photo to Cloudinary: ' . $e->getMessage()
            ], 500);
        }

        // Sync both attributes, and also the avatar column if it exists in the database
        if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'avatar')) {
            $user->avatar = $path;
        } else {
            $user->profile_photo = $path;
            $user->profile_picture = $path;
        }
        $user->save();
        $user->append('stats');

        return response()->json([
            'message' => 'Profile photo updated',
            'profile_photo_url' => $path,
            'user' => $user
        ]);
    }

    protected function uploadToCloudinary($file)
    {
        $timestamp = time();
        $params = [
            'folder' => 'avatars',
            'timestamp' => $timestamp,
        ];

        ksort($params);

        $parameterString = '';
        foreach ($params as $key => $value) {
            $parameterString .= "{$key}={$value}&";
        }
        $parameterString = rtrim($parameterString, '&');

        $apiSecret = env('CLOUDINARY_API_SECRET');
        $stringToSign = $parameterString . $apiSecret;
        $signature = sha1($stringToSign);

        $cloudName = env('CLOUDINARY_CLOUD_NAME');
        $url = "https://api.cloudinary.com/v1_1/{$cloudName}/image/upload";

        $response = Http::attach(
            'file',
            file_get_contents($file->getRealPath()),
            $file->getClientOriginalName()
        )->post($url, array_merge($params, [
            'api_key' => env('CLOUDINARY_API_KEY'),
            'signature' => $signature,
        ]));

        if ($response->successful()) {
            return $response->json('secure_url');
        }

        throw new \Exception($response->json('error.message') ?? 'Unknown Cloudinary error');
    }

    protected function deleteFromCloudinary($url)
    {
        $publicId = $this->getPublicIdFromUrl($url);
        if (!$publicId) return;

        $timestamp = time();
        $params = [
            'public_id' => $publicId,
            'timestamp' => $timestamp,
        ];

        ksort($params);

        $parameterString = '';
        foreach ($params as $key => $value) {
            $parameterString .= "{$key}={$value}&";
        }
        $parameterString = rtrim($parameterString, '&');

        $apiSecret = env('CLOUDINARY_API_SECRET');
        $stringToSign = $parameterString . $apiSecret;
        $signature = sha1($stringToSign);

        $cloudName = env('CLOUDINARY_CLOUD_NAME');
        $destroyUrl = "https://api.cloudinary.com/v1_1/{$cloudName}/image/destroy";

        Http::post($destroyUrl, array_merge($params, [
            'api_key' => env('CLOUDINARY_API_KEY'),
            'signature' => $signature,
        ]));
    }

    protected function getPublicIdFromUrl($url)
    {
        // Extract public_id from Cloudinary URL:
        // https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{public_id}.{extension}
        $pattern = '/image\/upload\/(?:v\d+\/)?([^\.]+)/';
        if (preg_match($pattern, $url, $matches)) {
            return $matches[1];
        }
        return null;
    }

    public function updateProfile(Request $request)
    {
        /** @var User $user */
        $user = auth()->user();

        $validated = $request->validate([
            'name' => 'nullable|string|max:255',
            'phone_number' => 'nullable|string|max:20|unique:users,phone_number,' . $user->id,
            'email' => 'nullable|string|email|max:255|unique:users,email,' . $user->id,
            'hide_phone' => 'nullable|boolean',
            'theme_preference' => 'nullable|string|in:system,activeSteelBlue,elegantLavender',
            'bio' => 'nullable|string|max:1000',
            'primary_sport' => 'nullable|string|max:255',
            'skill_tier' => 'nullable|string|max:255',
            'gender' => 'nullable|string|in:male,female,other',
        ]);

        if (array_key_exists('name', $validated)) {
            $user->name = $validated['name'];
        }
        if (array_key_exists('phone_number', $validated)) {
            $user->phone_number = $validated['phone_number'];
        }
        if (array_key_exists('email', $validated)) {
            $user->email = $validated['email'];
        }
        if (array_key_exists('hide_phone', $validated)) {
            $user->hide_phone = $validated['hide_phone'];
        }
        if (array_key_exists('theme_preference', $validated)) {
            $user->theme_preference = $validated['theme_preference'];
        }
        if (array_key_exists('bio', $validated)) {
            $user->bio = $validated['bio'];
        }
        if (array_key_exists('primary_sport', $validated)) {
            $user->primary_sport = $validated['primary_sport'];
        }
        if (array_key_exists('skill_tier', $validated)) {
            $user->skill_tier = $validated['skill_tier'];
        }
        if (array_key_exists('gender', $validated)) {
            $user->gender = $validated['gender'];
        }

        $user->save();
        $user->append(['stats', 'followersCount', 'followingCount']);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    public function players(Request $request)
    {
        $currentUser = $request->user();
        $query = User::where('id', '!=', $currentUser->id);

        if ($request->filled('search')) {
            $searchTerm = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', $searchTerm)
                  ->orWhere('username', 'like', $searchTerm)
                  ->orWhere('primary_sport', 'like', $searchTerm);
            });
        }

        $players = $query->latest()->take(15)->get();

        foreach ($players as $player) {
            $player->append('isFollowed');
        }
            
        return response()->json([
            'success' => true,
            'data' => $players
        ]);
    }
}
