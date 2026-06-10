<?php

namespace App\Http\Controllers;

use App\Models\Activity;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index()
    {
        return response()->json(Activity::latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|string',
            'message' => 'required|string',
            'meta' => 'nullable|array'
        ]);

        $validated['user_id'] = auth()->id();

        $activity = Activity::create($validated);
        return response()->json($activity, 201);
    }
    
    public function update(Request $request, Activity $activity)
    {
        if ($activity->user_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'message' => 'required|string'
        ]);
        
        $activity->update($validated);
        return response()->json($activity);
    }
}
