<?php

namespace App\Http\Controllers;

use App\Models\SportsMatch;
use App\Models\Activity;
use App\Models\PlayerRating;
use Illuminate\Http\Request;
use Carbon\Carbon;

class MatchController extends Controller
{
    public function index()
    {
        return SportsMatch::with(['user', 'participants'])->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'category' => 'nullable|string',
            'sport_type' => 'nullable|string',
            'location' => 'required|string',
            'date' => 'nullable|string',
            'date_time' => 'nullable|string',
            'price' => 'nullable|string',
            'max_slots' => 'nullable|integer',
            'maxSlots' => 'nullable|integer',
            'skill_level' => 'nullable|string',
            'skillLevel' => 'nullable|string',
            'is_women_only' => 'boolean|nullable',
            'women_only' => 'boolean|nullable',
        ]);

        $sportType = $request->sport_type ?? $request->category ?? 'Football';
        $dateTime = $request->date_time ?? $request->date ?? now()->toDateTimeString();
        $maxSlots = $request->max_slots ?? $request->maxSlots ?? 10;
        $skillLevel = $request->skill_level ?? $request->skillLevel ?? 'Intermediate';
        $womenOnly = $request->women_only ?? $request->is_women_only ?? false;

        $user = auth()->user();
        if ($womenOnly && strtolower($user->gender) !== 'female') {
            return response()->json(['message' => 'Only female athletes can host women-only matches.'], 403);
        }

        try {
            $matchDate = Carbon::parse($dateTime);
            if ($matchDate->isPast() && $matchDate->diffInHours(Carbon::now(), false) > 2) {
                return response()->json([
                    'message' => 'Cannot create a match in the past. Please select today or a future date/time.'
                ], 422);
            }
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Invalid date or time format.'
            ], 422);
        }

        $match = \Illuminate\Support\Facades\DB::transaction(function () use ($request, $user, $sportType, $dateTime, $maxSlots, $skillLevel, $womenOnly) {
            $newMatch = SportsMatch::create([
                'creator_id' => $user->id,
                'title' => $request->title,
                'sport_type' => $sportType,
                'location' => $request->location,
                'date_time' => $dateTime,
                'available_slots' => $maxSlots - 1,
                'max_slots' => $maxSlots,
                'skill_level' => $skillLevel,
                'status' => 'open',
                'women_only' => $womenOnly
            ]);

            // Only attach as participant if they satisfy the gender restriction
            if (!($newMatch->women_only && strtolower($user->gender) !== 'female')) {
                $newMatch->participants()->attach($user->id);
            }

            // Create activity record
            Activity::create([
                'user_id' => $user->id,
                'type' => 'match_created',
                'message' => "{$user->name} created a {$sportType} match: \"{$request->title}\" at {$request->location}",
                'meta' => [
                    'title' => $request->title,
                    'location' => $request->location,
                    'match_id' => $newMatch->id,
                    'sport_type' => $sportType
                ]
            ]);

            return $newMatch;
        });

        return response()->json($match->load(['user', 'participants']), 201);
    }

    public function show(SportsMatch $match)
    {
        return response()->json($match->load(['user', 'participants']));
    }

    public function update(Request $request, SportsMatch $match)
    {
        $request->validate([
            'title' => 'required|string',
            'category' => 'nullable|string',
            'sport_type' => 'nullable|string',
            'location' => 'required|string',
            'date' => 'nullable|string',
            'date_time' => 'nullable|string',
            'max_slots' => 'nullable|integer',
            'maxSlots' => 'nullable|integer',
            'skill_level' => 'nullable|string',
            'skillLevel' => 'nullable|string',
            'is_women_only' => 'boolean|nullable',
            'women_only' => 'boolean|nullable',
        ]);

        $sportType = $request->sport_type ?? $request->category ?? $match->sport_type;
        $dateTime = $request->date_time ?? $request->date ?? $match->date_time;
        $maxSlots = $request->max_slots ?? $request->maxSlots ?? $match->max_slots;
        $skillLevel = $request->skill_level ?? $request->skillLevel ?? $match->skill_level;
        $womenOnly = $request->women_only ?? $request->is_women_only ?? $match->women_only;

        $user = auth()->user();
        if ($womenOnly && strtolower($user->gender) !== 'female') {
            return response()->json(['message' => 'Only female athletes can host women-only matches.'], 403);
        }

        try {
            $matchDate = Carbon::parse($dateTime);
            if ($matchDate->isPast() && $matchDate->diffInHours(Carbon::now(), false) > 2) {
                return response()->json([
                    'message' => 'Cannot update a match to a past date.'
                ], 422);
            }
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Invalid date or time format.'
            ], 422);
        }

        $participantsCount = $match->participants()->count();
        $availableSlots = max(0, $maxSlots - $participantsCount);
        $status = $availableSlots <= 0 ? 'full' : 'open';

        $match->update([
            'title' => $request->title,
            'sport_type' => $sportType,
            'location' => $request->location,
            'date_time' => $dateTime,
            'max_slots' => $maxSlots,
            'available_slots' => $availableSlots,
            'skill_level' => $skillLevel,
            'women_only' => $womenOnly,
            'status' => $status,
        ]);

        return response()->json($match->load(['user', 'participants']));
    }

    public function join(SportsMatch $match)
    {
        $user = auth()->user();
        
        if ($match->women_only && strtolower($user->gender) !== 'female') {
            return response()->json(['message' => 'This match is restricted to women only.'], 403);
        }

        if ($match->participants()->where('user_id', $user->id)->exists()) {
            return response()->json(['message' => 'You have already joined this match.'], 400);
        }

        if ($match->available_slots <= 0) {
            return response()->json(['message' => 'This match is already full.'], 400);
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($match, $user) {
            $match->participants()->attach($user->id);
            $match->decrement('available_slots');
            if ($match->available_slots <= 0) {
                $match->update(['status' => 'full']);
            }

            // Log activity
            Activity::create([
                'user_id' => $user->id,
                'type' => 'match_joined',
                'message' => "{$user->name} joined the {$match->sport_type} match: \"{$match->title}\" at {$match->location}",
                'meta' => [
                    'title' => $match->title,
                    'location' => $match->location,
                    'match_id' => $match->id,
                    'sport_type' => $match->sport_type
                ]
            ]);
        });

        return response()->json([
            'message' => 'Successfully joined the match!',
            'match' => $match->fresh(['user', 'participants'])
        ]);
    }

    public function leave(SportsMatch $match)
    {
        $user = auth()->user();
        
        if (!$match->participants()->where('user_id', $user->id)->exists()) {
            return response()->json(['message' => 'You are not joined to this match.'], 400);
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($match, $user) {
            $match->participants()->detach($user->id);
            $match->increment('available_slots');
            $match->update(['status' => 'open']);

            // Log activity
            Activity::create([
                'user_id' => $user->id,
                'type' => 'match_left',
                'message' => "{$user->name} left the {$match->sport_type} match: \"{$match->title}\" at {$match->location}",
                'meta' => [
                    'title' => $match->title,
                    'location' => $match->location,
                    'match_id' => $match->id,
                    'sport_type' => $match->sport_type
                ]
            ]);
        });

        return response()->json([
            'message' => 'Successfully left the match!',
            'match' => $match->fresh(['user', 'participants'])
        ]);
    }

    public function userMatches(Request $request)
    {
        $user = auth()->user();
        
        // Fetch matches hosted by the user
        $hostedMatches = SportsMatch::where('creator_id', $user->id)->get();
        
        // Fetch matches the user joined
        $joinedMatches = $user->joinedMatches()->get();
        
        // Combine them and ensure no duplicates
        $allMatches = $hostedMatches->merge($joinedMatches)->unique('id')->values();

        return response()->json($allMatches);
    }

    public function destroy(SportsMatch $match)
    {
        $user = auth()->user();
        if ($match->creator_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized to delete this match.'], 403);
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($match) {
            $match->participants()->detach();
            $match->delete();

            // Clean up related activities
            Activity::where('meta->match_id', $match->id)->delete();
            Activity::where('message', 'like', "%{$match->title}%")->delete();
        });

        return response()->json(['message' => 'Match deleted successfully!']);
    }

    /**
     * Record match results (win/loss/draw) for participants.
     * Only the match creator can record results, and the match must be in the past.
     */
    public function recordResults(Request $request, SportsMatch $match)
    {
        $user = auth()->user();

        // Only the match creator can record results
        if ((int) $match->creator_id !== (int) $user->id) {
            return response()->json(['message' => 'Only the match organizer can record results.'], 403);
        }

        // Match must be in the past
        $matchDate = Carbon::parse($match->date_time);
        if ($matchDate->isFuture()) {
            return response()->json(['message' => 'Cannot record results for a match that has not yet been played.'], 422);
        }

        $request->validate([
            'results' => 'required|array|min:1',
            'results.*.user_id' => 'required|integer',
            'results.*.result' => 'required|string|in:win,loss,draw',
        ]);

        $participantIds = $match->participants()->pluck('users.id')->toArray();

        \Illuminate\Support\Facades\DB::transaction(function () use ($match, $request, $participantIds) {
            foreach ($request->results as $entry) {
                $userId = (int) $entry['user_id'];
                $result = $entry['result'];

                // Only update if the user is actually a participant
                if (in_array($userId, $participantIds)) {
                    $match->participants()->updateExistingPivot($userId, ['result' => $result]);
                }
            }
        });

        return response()->json([
            'message' => 'Match results recorded successfully!',
            'match' => $match->fresh(['user', 'participants'])
        ]);
    }

    public function mine(Request $request)
    {
        $user = auth()->user();
        $matches = SportsMatch::with(['user', 'participants'])
            ->whereHas('participants', function ($query) use ($user) {
                $query->where('user_id', $user->id);
            })
            ->orderBy('date_time', 'desc')
            ->get();

        return response()->json($matches);
    }

    /**
     * Submit ratings for players in a match.
     */
    public function submitRatings(Request $request, SportsMatch $match)
    {
        $user = auth()->user();

        // User must be a participant in the match
        if (!$match->participants()->where('user_id', $user->id)->exists()) {
            return response()->json(['message' => 'You must be a participant in this match to submit ratings.'], 403);
        }

        // Match must be in the past
        $matchDate = Carbon::parse($match->date_time);
        if ($matchDate->isFuture()) {
            return response()->json(['message' => 'Cannot submit ratings for a match that has not yet been played.'], 422);
        }

        $request->validate([
            'ratings' => 'required|array|min:1',
            'ratings.*.user_id' => 'required|integer',
            'ratings.*.rating' => 'required|integer|min:1|max:5',
        ]);

        $savedRatings = [];

        foreach ($request->ratings as $entry) {
            $ratedUserId = (int) $entry['user_id'];

            // User can't rate themselves
            if ($ratedUserId === (int) $user->id) {
                continue;
            }

            $rating = PlayerRating::updateOrCreate(
                [
                    'match_id' => $match->id,
                    'rater_id' => $user->id,
                    'rated_id' => $ratedUserId,
                ],
                [
                    'rating' => $entry['rating'],
                ]
            );

            $savedRatings[] = $rating;
        }

        return response()->json([
            'message' => 'Ratings submitted successfully!',
            'ratings' => $savedRatings,
        ]);
    }

    /**
     * Get all ratings for a match.
     */
    public function getRatings(SportsMatch $match)
    {
        $ratings = PlayerRating::where('match_id', $match->id)
            ->with(['rater:id,name', 'rated:id,name'])
            ->get();

        return response()->json($ratings);
    }
}
