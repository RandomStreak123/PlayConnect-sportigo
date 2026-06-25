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
        $user = auth()->user();

        // 1. Get all match IDs created by the authenticated user
        $myMatchIds = \App\Models\SportsMatch::where('creator_id', $user->id)->pluck('id');

        // 2. Query activities:
        // - match_joined/match_left activities by other users on matches created by the current user
        if ($myMatchIds->isEmpty()) {
            // Return empty paginated structure
            $paginated = Activity::whereRaw('1 = 0')->paginate(15);
        } else {
            $paginated = Activity::with('user:id,name,avatar,gender')
                ->whereIn('type', ['match_joined', 'match_left'])
                ->where('user_id', '!=', $user->id)
                ->whereIn('meta->match_id', $myMatchIds)
                ->latest()
                ->paginate(15);
        }

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
        $activities = Activity::with('user:id,name,avatar,gender')
            ->whereIn('type', ['match_joined', 'match_left'])
            ->where('user_id', '!=', $user->id)             // exclude own actions
            ->whereIn('meta->match_id', $myMatchIds)         // only for my matches
            ->latest()
            ->get();

        return response()->json(['data' => $activities]);
    }
}
