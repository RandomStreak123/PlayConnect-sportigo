<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index()
    {
        $userId = auth()->id();
        $matchIds = \App\Models\SportsMatch::where('creator_id', $userId)->pluck('id');

        $paginated = Activity::with('user:id,name,profile_picture,profile_photo,gender')
            ->whereIn('type', ['match_joined', 'match_left'])
            ->whereIn('meta->match_id', $matchIds)
            ->where('user_id', '!=', $userId)
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => $paginated->items(),
            'next_page' => $paginated->hasMorePages() ? $paginated->currentPage() + 1 : null,
        ]);
    }
}
