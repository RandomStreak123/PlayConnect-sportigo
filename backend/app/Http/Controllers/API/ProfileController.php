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

    public function updateProfile(Request $request)
    {
        /** @var User $user */
        $user = auth()->user();

        $validated = $request->validate([
            'name' => 'nullable|string|max:255',
            'phone_number' => 'nullable|string|max:20|unique:users,phone_number,' . $user->id,
            'hide_phone' => 'nullable|boolean',
            'theme_preference' => 'nullable|string|in:system,activeSteelBlue,elegantLavender',
        ]);

        if (array_key_exists('name', $validated)) {
            $user->name = $validated['name'];
        }
        if (array_key_exists('phone_number', $validated)) {
            $user->phone_number = $validated['phone_number'];
        }
        if (array_key_exists('hide_phone', $validated)) {
            $user->hide_phone = $validated['hide_phone'];
        }
        if (array_key_exists('theme_preference', $validated)) {
            $user->theme_preference = $validated['theme_preference'];
        }

        // Gender is set once at registration and cannot be changed afterward.
        if ($request->has('gender')) {
            return response()->json([
                'message' => 'Gender can only be set during registration.',
            ], 422);
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }
}
