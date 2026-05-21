<?php

namespace App\Http\Controllers;

use App\Models\SportMatch;
use App\Services\MatchSlotService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

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
        $query = SportMatch::with('users:id,name,profile_picture');

        if ($request->filled('sport_type')) {
            $query->where('sport_type', $request->input('sport_type'));
        }

        if ($request->filled('skill_level')) {
            $query->where('skill_level', $request->input('skill_level'));
        }

        if ($request->filled('search')) {
            // Prefix search only — allows index usage on title/location.
            // For full substring search, consider MySQL FULLTEXT index or Meilisearch.
            $searchTerm = $request->input('search').'%';
            $query->where(function ($q) use ($searchTerm) {
                $q->where('title', 'like', $searchTerm)
                    ->orWhere('location', 'like', $searchTerm);
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
        $matches = SportMatch::with('users:id,name,profile_picture')
            ->whereHas('users', function ($query) use ($request) {
                $query->where('user_id', $request->user()->id);
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
            'date_time' => 'required|date|after:now',
            'location' => 'required|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'available_slots' => 'required|integer|min:1',
            'skill_level' => ['required', 'string', Rule::in(self::SKILL_LEVELS)],
            'women_only' => 'nullable|boolean',
        ]);

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

    public function show(SportMatch $match)
    {
        $match->load('users:id,name,profile_picture');

        return response()->json($this->slotService->syncMatch($match));
    }

    public function update(Request $request, SportMatch $match)
    {
        if ($match->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'sport_type' => ['sometimes', 'string', Rule::in(self::SPORT_TYPES)],
            'title' => 'sometimes|string|max:255',
            'date_time' => 'sometimes|date|after:now',
            'location' => 'sometimes|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'available_slots' => 'sometimes|integer|min:0',
            'skill_level' => ['sometimes', 'string', Rule::in(self::SKILL_LEVELS)],
            'women_only' => 'nullable|boolean',
        ]);

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
            $match = $match->load('users:id,name,profile_picture');
        }

        return response()->json($match);
    }

    public function destroy(Request $request, SportMatch $match)
    {
        if ($match->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $match->delete();

        return response()->noContent();
    }

    public function join(Request $request, SportMatch $match)
    {
        if ($match->women_only && $request->user()->gender !== 'female') {
            return response()->json([
                'message' => 'This match is reserved for female players only.',
                'error_code' => 'FEMALE_ONLY_MATCH_RESTRICTION',
            ], 403);
        }

        $result = $this->slotService->join($match, $request->user());

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Successfully joined',
            'match' => $result['match'],
        ]);
    }

    public function leave(Request $request, SportMatch $match)
    {
        $result = $this->slotService->leave($match, $request->user());

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Successfully left',
            'match' => $result['match'],
        ]);
    }
}
