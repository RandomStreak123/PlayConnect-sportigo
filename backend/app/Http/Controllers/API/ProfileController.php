<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Storage;
use App\Models\User;

class ProfileController extends Controller
{
    public function uploadProfilePhoto(Request $request, \App\Services\SupabaseStorageService $supabaseService)
    {
        $request->validate([
            'profile_photo' => 'required|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        /** @var User $user */
        $user = auth()->user();

        // Try to upload to Supabase Storage
        $publicUrl = $supabaseService->upload($request->file('profile_photo'));

        if ($publicUrl) {
            // Delete old profile photos from Supabase if they exist
            if ($user->profile_photo && str_starts_with($user->profile_photo, 'http')) {
                $supabaseService->delete($user->profile_photo);
            }
            if ($user->profile_picture && str_starts_with($user->profile_picture, 'http') && $user->profile_picture !== $user->profile_photo) {
                $supabaseService->delete($user->profile_picture);
            }

            $path = $publicUrl;
        } else {
            // Fallback to local public disk storage
            if ($user->profile_photo && !str_starts_with($user->profile_photo, 'http')) {
                Storage::disk('public')->delete($user->profile_photo);
            }
            if ($user->profile_picture && !str_starts_with($user->profile_picture, 'assets/') && !str_starts_with($user->profile_picture, 'http') && $user->profile_picture !== $user->profile_photo) {
                Storage::disk('public')->delete($user->profile_picture);
            }

            $path = $request->file('profile_photo')->store('profile-images', 'public');
        }

        // Sync both attributes, and also the avatar column if it exists in the database
        if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'avatar')) {
            $user->avatar = $path;
        } else {
            $user->profile_photo = $path;
            $user->profile_picture = $path;
        }
        $user->save();

        return response()->json([
            'message' => 'Profile photo updated',
            'profile_photo_url' => str_starts_with($path, 'http') ? $path : asset('storage/' . $path),
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

        // Gender is set once at registration and cannot be changed afterward if already set.
        if ($request->has('gender')) {
            if ($user->gender !== null) {
                return response()->json([
                    'message' => 'Gender can only be set during registration or initial profile setup.',
                ], 422);
            }

            $validatedGender = $request->validate([
                'gender' => 'required|string|in:male,female,other',
            ]);
            $user->gender = $validatedGender['gender'];
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    public function players(Request $request)
    {
        $currentUser = $request->user();
        
        $players = User::where('id', '!=', $currentUser->id)
            ->latest()
            ->take(15)
            ->get();
            
        return response()->json([
            'success' => true,
            'data' => $players
        ]);
    }
}
