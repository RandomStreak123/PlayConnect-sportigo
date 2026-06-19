<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UserController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'phone_number' => $user->phone_number,
            'gender' => $user->gender,
            'avatar' => $user->avatar,
            'profile_picture' => $user->profile_picture,
            'profile_photo' => $user->profile_photo,
            'bio' => $user->bio,
            'primary_sport' => $user->primary_sport,
            'skill_tier' => $user->skill_tier,
            'hide_phone' => $user->hide_phone,
            'theme_preference' => $user->theme_preference,
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:120',
            'email' => 'nullable|email|max:255|unique:users,email,' . $request->user()->id,
            'phone' => 'nullable|string|max:32',
            'bio' => 'nullable|string|max:500',
            'primary_sport' => 'nullable|string|max:64',
            'skill_tier' => 'nullable|string|max:64',
            'gender' => 'nullable|string|in:male,female',
            'avatar' => 'nullable|string|max:120000',
            'profile_picture' => 'nullable|string|max:120000',
            'profile_photo' => 'nullable|string|max:120000',
        ]);

        $user = $request->user();
        $user->update($validated);

        $freshUser = $user->fresh();
        return response()->json([
            'id' => $freshUser->id,
            'name' => $freshUser->name,
            'username' => $freshUser->username,
            'email' => $freshUser->email,
            'phone' => $freshUser->phone,
            'phone_number' => $freshUser->phone_number,
            'gender' => $freshUser->gender,
            'avatar' => $freshUser->avatar,
            'profile_picture' => $freshUser->profile_picture,
            'profile_photo' => $freshUser->profile_photo,
            'bio' => $freshUser->bio,
            'primary_sport' => $freshUser->primary_sport,
            'skill_tier' => $freshUser->skill_tier,
            'hide_phone' => $freshUser->hide_phone,
            'theme_preference' => $freshUser->theme_preference,
        ]);
    }

    public function stats(Request $request)
    {
        $startTime = microtime(true);
        $user = $request->user();
        $stats = $user->stats;
        $duration = (microtime(true) - $startTime) * 1000;
        \Illuminate\Support\Facades\Log::info("UserController::stats executed in {$duration}ms for User ID {$user->id}");
        return response()->json($stats);
    }

    public function history(Request $request)
    {
        $startTime = microtime(true);
        $user = $request->user();
        $user->loadMissing(['joinedMatches.participants', 'hostedMatches.participants']);
        $allMatches = $user->hostedMatches->merge($user->joinedMatches)->unique('id')->values();
        $duration = (microtime(true) - $startTime) * 1000;
        \Illuminate\Support\Facades\Log::info("UserController::history executed in {$duration}ms for User ID {$user->id}");
        return response()->json($allMatches);
    }

    public function ratings(Request $request)
    {
        $startTime = microtime(true);
        $user = $request->user();
        $ratings = \App\Models\PlayerRating::where('rated_id', $user->id)->get();
        $duration = (microtime(true) - $startTime) * 1000;
        \Illuminate\Support\Facades\Log::info("UserController::ratings executed in {$duration}ms for User ID {$user->id}");
        return response()->json($ratings);
    }

    public function publicProfile($id)
    {
        $user = \App\Models\User::with([
            'joinedMatches.participants',
            'hostedMatches.participants',
            'tournaments'
        ])->findOrFail($id);
        
        // Merge hosted and joined matches for their public activity feed
        $allMatches = $user->hostedMatches->merge($user->joinedMatches)->unique('id')->values();

        $activities = \App\Models\Activity::where('user_id', $user->id)->latest()->get();

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'gender' => $user->gender,
            'avatar' => $user->avatar,
            'bio' => $user->bio,
            'primary_sport' => $user->primary_sport,
            'skill_tier' => $user->skill_tier,
            'matches' => $allMatches,
            'stats' => $user->stats,
            'activities' => $activities,
            'tournaments' => $user->tournaments,
            'created_at' => $user->created_at,
        ]);
    }

    public function wave($id)
    {
        $targetUser = \App\Models\User::findOrFail($id);
        $currentUser = auth()->user();

        if ($currentUser->id === $targetUser->id) {
            return response()->json(['message' => 'You cannot wave at yourself'], 422);
        }

        // Create notification for B (the target user)
        \App\Models\Notification::create([
            'user_id' => $targetUser->id,
            'type' => 'social',
            'title' => 'New Wave',
            'message' => $currentUser->name . ' waved a hii 👋',
            'meta' => ['sender_id' => $currentUser->id, 'sender_name' => $currentUser->name],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Waved successfully'
        ]);
    }
}
