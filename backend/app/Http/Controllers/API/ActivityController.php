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
            ->get();

        return response()->json($activities);
    }
}
