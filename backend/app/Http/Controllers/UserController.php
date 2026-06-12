<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UserController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        $user->append('stats');
        return response()->json($user);
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
        $freshUser->append('stats');
        return response()->json($freshUser);
    }

    public function publicProfile($id)
    {
        $user = \App\Models\User::with(['joinedMatches.participants', 'joinedMatches.user', 'tournaments'])->findOrFail($id);
        $hostedMatches = \App\Models\SportsMatch::with(['user', 'participants'])->where('creator_id', $user->id)->get();
        
        // Merge hosted and joined matches for their public activity feed
        $allMatches = $hostedMatches->merge($user->joinedMatches)->unique('id')->values();

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
}
