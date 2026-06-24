<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UserController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        $user->append(['stats', 'followersCount', 'followingCount']);
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
        $oldEmail = $user->email;
        
        $user->update($validated);

        if (empty($oldEmail) && !empty($user->email)) {
            $frontendUrl = $request->header('Origin') ?: $request->header('Referer');
            if ($frontendUrl) {
                $frontendUrl = preg_replace('/(\/auth|\/login|\/forgot-password|\/register|\/reset-password|\/profile).*$/', '', $frontendUrl);
                $frontendUrl = rtrim($frontendUrl, '/');
            } else {
                $frontendUrl = 'https://playconnect-vue.ddev.site';
            }
            try {
                \Illuminate\Support\Facades\Mail::to($user->email)->send(new \App\Mail\WelcomeMail($user->name, $frontendUrl));
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error("Failed to send welcome email on profile update to {$user->email}: " . $e->getMessage());
            }
        }

        $freshUser = $user->fresh();
        $freshUser->append(['stats', 'followersCount', 'followingCount']);
        return response()->json($freshUser);
    }

    public function publicProfile($id)
    {
        $user = \App\Models\User::with(['joinedMatches.user', 'joinedMatches.participants', 'tournaments'])->findOrFail($id);
        $hostedMatches = \App\Models\SportsMatch::with(['user', 'participants'])->where('creator_id', $user->id)->get();
        
        // Merge hosted and joined matches for their public activity feed
        $allMatches = $hostedMatches->merge($user->joinedMatches)->unique('id')->values();

        $activities = \App\Models\Activity::with('user')->where('user_id', $user->id)->latest()->get();

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
            'followersCount' => $user->followersCount,
            'followingCount' => $user->followingCount,
            'isFollowed' => $user->isFollowed,
        ]);
    }

    public function follow($id)
    {
        $targetUser = \App\Models\User::findOrFail($id);
        $currentUser = auth()->user();

        if ($currentUser->id === $targetUser->id) {
            return response()->json(['message' => 'You cannot follow yourself'], 422);
        }

        $alreadyFollowing = $currentUser->following()->where('followed_id', $targetUser->id)->exists();

        if (!$alreadyFollowing) {
            $currentUser->following()->syncWithoutDetaching($targetUser->id);

            // Create notification for B (the target user)
            \App\Models\Notification::create([
                'user_id' => $targetUser->id,
                'type' => 'follow',
                'title' => 'New Follower',
                'message' => $currentUser->name . ' started following you!',
                'meta' => ['follower_id' => $currentUser->id, 'follower_name' => $currentUser->name],
            ]);

            // Create activity for A (the follower)
            \App\Models\Activity::create([
                'user_id' => $currentUser->id,
                'type' => 'follow',
                'message' => 'started following ' . $targetUser->name,
                'meta' => ['followed_id' => $targetUser->id, 'followed_name' => $targetUser->name],
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Followed successfully',
            'followersCount' => $targetUser->followers()->count(),
            'isFollowed' => true
        ]);
    }

    public function unfollow($id)
    {
        $targetUser = \App\Models\User::findOrFail($id);
        $currentUser = auth()->user();

        $currentUser->following()->detach($targetUser->id);

        return response()->json([
            'success' => true,
            'message' => 'Unfollowed successfully',
            'followersCount' => $targetUser->followers()->count(),
            'isFollowed' => false
        ]);
    }

    public function followers($id)
    {
        $user = \App\Models\User::findOrFail($id);
        $followers = $user->followers()->get();
        foreach ($followers as $follower) {
            $follower->append('isFollowed');
        }
        return response()->json($followers);
    }

    public function following($id)
    {
        $user = \App\Models\User::findOrFail($id);
        $following = $user->following()->get();
        foreach ($following as $followed) {
            $followed->append('isFollowed');
        }
        return response()->json($following);
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
