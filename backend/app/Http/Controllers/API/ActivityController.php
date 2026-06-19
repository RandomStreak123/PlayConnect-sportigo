<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\SportsMatch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ActivityController extends Controller
{
    /**
     * Global activity feed (paginated, latest 15).
     */
    public function index()
    {
        $paginated = Activity::with('user:id,name,profile_picture,profile_photo,gender')
            ->latest()
            ->paginate(15);

        return response()->json([
            'data'      => $paginated->items(),
            'next_page' => $paginated->hasMorePages() ? $paginated->currentPage() + 1 : null,
        ]);
    }

    /**
     * Activities on matches the authenticated user created.
     * Returns join/leave events by OTHER users on the current user's matches — all of them, no pagination limit.
     */
    public function forMyMatches(Request $request)
    {
        $user = Auth::user();

        // Get all match IDs created by this user
        $myMatchIds = SportsMatch::where('creator_id', $user->id)->pluck('id');

        if ($myMatchIds->isEmpty()) {
            return response()->json(['data' => []]);
        }

        // Get join/leave activities on those matches by OTHER users, ordered newest first
        $activities = Activity::with('user:id,name,profile_picture,profile_photo,gender')
            ->whereIn('type', ['match_joined', 'match_left'])
            ->where('user_id', '!=', $user->id)             // exclude own actions
            ->whereIn('meta->match_id', $myMatchIds)         // only for my matches
            ->latest()
            ->get();

        return response()->json(['data' => $activities]);
    }
}
