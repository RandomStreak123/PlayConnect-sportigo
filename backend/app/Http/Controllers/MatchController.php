<?php

namespace App\Http\Controllers;

use App\Models\SportsMatch;
use App\Models\Activity;
use App\Models\PlayerRating;
use App\Services\MatchSlotService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class MatchController extends Controller
{
    private const SPORT_TYPES = [
        'Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket',
    ];

    private const SKILL_LEVELS = [
        'Beginner', 'Intermediate', 'Advanced', 'Professional',
    ];

    public function __construct(
        private readonly MatchSlotService $slotService,
    ) {}

    public function index(Request $request)
    {
        $query = SportsMatch::with(['user', 'participants']);

        if ($request->filled('sport_type')) {
            $query->where('sport_type', $request->input('sport_type'));
        }

        if ($request->filled('skill_level')) {
            $query->where('skill_level', $request->input('skill_level'));
        }

        if ($request->filled('search')) {
            $searchTerm = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($searchTerm) {
                $q->where('title', 'like', $searchTerm)
                    ->orWhere('location', 'like', $searchTerm)
                    ->orWhere('sport_type', 'like', $searchTerm);
            });
        }

        if ($request->has('women_only')) {
            $query->where('women_only', $request->boolean('women_only'));
        }

        /** @var \Illuminate\Pagination\CursorPaginator $paginator */
        $paginator = $query
            ->where('date_time', '>=', now())
            ->orderBy('date_time')
            ->orderBy('id')          // secondary sort for stable cursor
            ->cursorPaginate(15, ['*'], 'cursor', $request->input('cursor'));

        // Sync slots in-memory on the current page only (not the whole table)
        $this->slotService->syncCollection($paginator->getCollection());

        return response()->json([
            'data'        => $paginator->items(),
            'next_cursor' => $paginator->nextCursor()?->encode(),
            'has_more'    => $paginator->hasMorePages(),
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

        $this->slotService->syncCollection($matches);

        return response()->json($matches);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'sport_type' => ['required', 'string', Rule::in(self::SPORT_TYPES)],
            'title' => 'required|string|max:255',
            'date_time' => 'required|date',
            'location' => 'required|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'available_slots' => 'required|integer|min:1',
            'skill_level' => ['required', 'string', Rule::in(self::SKILL_LEVELS)],
            'women_only' => 'nullable|boolean',
        ]);

        try {
            $matchDate = Carbon::parse($validated['date_time']);
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

        $womenOnly = $request->boolean('women_only');

        if ($womenOnly && $request->user()->gender !== 'female') {
            return response()->json([
                'message' => 'Only female players can create women-only matches.',
                'error_code' => 'FEMALE_ONLY_MATCH_RESTRICTION',
            ], 403);
        }

        $match = $this->slotService->createMatch(
            $validated,
            $request->user(),
            $womenOnly,
        );

        return response()->json($match, 201);
    }

    public function show(SportsMatch $match)
    {
        $match->load(['user', 'participants']);

        return response()->json($this->slotService->syncMatch($match));
    }

    public function update(Request $request, SportsMatch $match)
    {
        if ($match->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'sport_type' => ['sometimes', 'string', Rule::in(self::SPORT_TYPES)],
            'title' => 'sometimes|string|max:255',
            'date_time' => 'sometimes|date',
            'location' => 'sometimes|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'available_slots' => 'sometimes|integer|min:0',
            'skill_level' => ['sometimes', 'string', Rule::in(self::SKILL_LEVELS)],
            'women_only' => 'nullable|boolean',
        ]);

        if (isset($validated['date_time'])) {
            try {
                $matchDate = Carbon::parse($validated['date_time']);
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
        }

        if ($request->has('women_only')) {
            $womenOnly = $request->boolean('women_only');
            if ($womenOnly && $request->user()->gender !== 'female') {
                return response()->json([
                    'message' => 'Only female players can set women-only matches.',
                    'error_code' => 'FEMALE_ONLY_MATCH_RESTRICTION',
                ], 403);
            }
            $validated['women_only'] = $womenOnly;
        }

        if (array_key_exists('available_slots', $validated)) {
            $match = $this->slotService->updateOpenSlots(
                $match,
                (int) $validated['available_slots'],
            );
            unset($validated['available_slots']);
        }

        if (! empty($validated)) {
            $match->update($validated);
            $match = $match->load(['user', 'participants']);
        }

        return response()->json($match);
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

        return response()->noContent();
    }

    public function join(SportsMatch $match)
    {
        $user = auth()->user();
        if ($match->women_only && $user->gender !== 'female') {
            return response()->json([
                'message' => 'This match is restricted to women only.',
                'error_code' => 'FEMALE_ONLY_MATCH_RESTRICTION',
            ], 403);
        }

        $result = $this->slotService->join($match, $user);

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Successfully joined the match!',
            'match' => $result['match'],
        ]);
    }

    public function leave(SportsMatch $match)
    {
        $user = auth()->user();
        $result = $this->slotService->leave($match, $user);

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Successfully left the match!',
            'match' => $result['match'],
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
