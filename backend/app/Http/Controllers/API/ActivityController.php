<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index()
    {
        $activities = Activity::with('user:id,name,profile_picture,profile_photo,gender')
            ->latest()
            ->paginate(20);

        return response()->json($activities);
    }
}
