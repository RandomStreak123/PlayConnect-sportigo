<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index()
    {
        $paginated = Activity::with('user:id,name,profile_picture,profile_photo,gender')
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => $paginated->items(),
            'next_page' => $paginated->hasMorePages() ? $paginated->currentPage() + 1 : null,
        ]);
    }
}
