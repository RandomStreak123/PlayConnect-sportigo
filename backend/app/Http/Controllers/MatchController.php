<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\SportMatch;

class MatchController extends Controller
{
    public function index(Request $request)
    {
        $query = SportMatch::with('users:id,name,profile_picture');

        if ($request->has('sport_type') && $request->input('sport_type') !== '') {
            $query->where('sport_type', $request->input('sport_type'));
        }

        if ($request->has('skill_level') && $request->input('skill_level') !== '') {
            $query->where('skill_level', $request->input('skill_level'));
        }

        if ($request->has('search') && $request->input('search') !== '') {
            $searchTerm = '%' . $request->input('search') . '%';
            $query->where(function($q) use ($searchTerm) {
                $q->where('title', 'like', $searchTerm)
                  ->orWhere('location', 'like', $searchTerm);
            });
        }

        $matches = $query->latest()->get();
        return response()->json($matches);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'sport_type' => 'required|string',
            'title' => 'required|string',
            'date_time' => 'required|date',
            'location' => 'required|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'available_slots' => 'required|integer',
            'skill_level' => 'required|string',
        ]);

        $match = SportMatch::create($validated);
        
        // Optionally, add the creator to the match
        $match->users()->attach($request->user()->id);
        $match->decrement('available_slots');

        return response()->json($match->load('users:id,name,profile_picture'), 201);
    }

    public function show(string $id)
    {
        $match = SportMatch::with('users:id,name,profile_picture')->findOrFail($id);
        return response()->json($match);
    }

    public function update(Request $request, string $id)
    {
        $match = SportMatch::findOrFail($id);
        $match->update($request->all());
        return response()->json($match);
    }

    public function destroy(string $id)
    {
        $match = SportMatch::findOrFail($id);
        $match->delete();
        return response()->json(null, 204);
    }

    public function join(Request $request, string $id)
    {
        $match = SportMatch::findOrFail($id);
        
        if ($match->users()->where('user_id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'Already joined'], 400);
        }

        if ($match->available_slots <= 0) {
            return response()->json(['message' => 'Match is full'], 400);
        }

        $match->users()->attach($request->user()->id);
        $match->decrement('available_slots');
        return response()->json(['message' => 'Successfully joined']);
    }

    public function leave(Request $request, string $id)
    {
        $match = SportMatch::findOrFail($id);
        if ($match->users()->where('user_id', $request->user()->id)->exists()) {
            $match->users()->detach($request->user()->id);
            $match->increment('available_slots');
        }
        return response()->json(['message' => 'Successfully left']);
    }
}
