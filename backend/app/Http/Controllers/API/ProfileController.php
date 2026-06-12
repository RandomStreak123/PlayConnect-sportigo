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
        $user->loadMissing(['joinedMatches.participants', 'hostedMatches.participants']);
        $user->append('stats');

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
        $user->loadMissing(['joinedMatches.participants', 'hostedMatches.participants']);
        $user->append('stats');

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
            
        return response()->json([
            'success' => true,
            'data' => $players
        ]);
    }
}
