<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Storage;
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

        // Delete old profile photos from storage if they exist
        if ($user->profile_photo) {
            Storage::disk('public')->delete($user->profile_photo);
        }
        if ($user->profile_picture && !str_starts_with($user->profile_picture, 'assets/') && $user->profile_picture !== $user->profile_photo) {
            Storage::disk('public')->delete($user->profile_picture);
        }

        // Store new image
        $path = $request->file('profile_photo')->store('profile-images', 'public');

        // Sync both attributes
        $user->profile_photo = $path;
        $user->profile_picture = $path;
        $user->save();

        return response()->json([
            'message' => 'Profile photo updated',
            'profile_photo_url' => asset('storage/' . $path),
            'user' => $user
        ]);
    }
}
