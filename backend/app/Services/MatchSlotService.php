<?php

namespace App\Services;

use App\Models\SportMatch;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\ActivityService;

/**
 * Single source of truth for match capacity (slots).
 * Every join, leave, create, or read path must go through here so
 * available_slots / max_slots stay aligned with sport_match_user.
 */
class MatchSlotService
{
    public function syncMatch(SportMatch $match, bool $save = false): SportMatch
    {
        $match->syncAvailableSlots($save);

        if ($save) {
            return $match->fresh(['users:id,name,profile_picture']);
        }
        return $match;
    }

    public function syncCollection(Collection $matches, bool $save = false): Collection
    {
        $matches->each(fn (SportMatch $match) => $match->syncAvailableSlots($save));

        return $matches;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function createMatch(array $validated, User $user, bool $womenOnly): SportMatch
    {
        $maxSlots = (int) $validated['available_slots'];
        $openSlots = max(0, $maxSlots - 1);

        return DB::transaction(function () use ($validated, $womenOnly, $maxSlots, $user, $openSlots) {
            $match = SportMatch::create([
                ...collect($validated)->except('available_slots')->all(),
                'available_slots' => $openSlots,
                'max_slots' => $maxSlots,
                'women_only' => $womenOnly,
                'creator_id' => $user->id,
            ]);

            $match->users()->attach($user->id);
            $match->syncAvailableSlots();

            try {
                ActivityService::create(
                    $user->id,
                    'match_created',
                    "{$user->name} created a {$match->sport_type} match: \"{$match->title}\" at {$match->location}",
                    [
                        'match_id' => $match->id,
                        'sport_type' => $match->sport_type,
                        'title' => $match->title,
                        'location' => $match->location,
                    ]
                );
            } catch (\Exception $e) {
                Log::error('Activity feed failed: ' . $e->getMessage());
            }

            return $match->load('users:id,name,profile_picture');
        });
    }

    public function updateOpenSlots(SportMatch $match, int $totalSlots): SportMatch
    {
        return DB::transaction(function () use ($match, $totalSlots) {
            $match = SportMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();
            $joined = $match->users()->count();
            $openSlots = max(0, $totalSlots - $joined);
            
            $match->update([
                'available_slots' => $openSlots,
                'max_slots' => max($joined, $totalSlots),
            ]);
            $match->syncAvailableSlots();

            return $match->load('users:id,name,profile_picture');
        });
    }

    /**
     * @return array{error?: string, status?: int, match?: SportMatch}
     */
    public function join(SportMatch $match, User $user): array
    {
        return DB::transaction(function () use ($match, $user) {
            $match = SportMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();

            if ($match->users()->where('user_id', $user->id)->exists()) {
                return ['error' => 'Already joined', 'status' => 409];
            }

            if ($match->users()->count() >= $match->max_slots) {
                return ['error' => 'Match is full', 'status' => 409];
            }

            $match->users()->attach($user->id);
            $match->syncAvailableSlots();

            try {
                ActivityService::create(
                    $user->id,
                    'match_joined',
                    "{$user->name} joined the {$match->sport_type} match: \"{$match->title}\" at {$match->location}",
                    [
                        'match_id' => $match->id,
                        'sport_type' => $match->sport_type,
                        'title' => $match->title,
                        'location' => $match->location,
                    ]
                );
            } catch (\Exception $e) {
                Log::error('Activity feed failed: ' . $e->getMessage());
            }

            return ['match' => $match->load('users:id,name,profile_picture')];
        });
    }

    /**
     * @return array{error?: string, status?: int, match?: SportMatch}
     */
    public function leave(SportMatch $match, User $user): array
    {
        if (! $match->users()->where('user_id', $user->id)->exists()) {
            return ['error' => 'You are not a member of this match', 'status' => 404];
        }

        if ($match->creator_id === $user->id) {
            return [
                'error' => 'Match creators cannot leave. Delete the match instead.',
                'status' => 403,
            ];
        }

        return DB::transaction(function () use ($match, $user) {
            $match = SportMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();
            $match->users()->detach($user->id);
            $match->syncAvailableSlots();

            try {
                ActivityService::create(
                    $user->id,
                    'match_left',
                    "{$user->name} left the {$match->sport_type} match: \"{$match->title}\" at {$match->location}",
                    [
                        'match_id' => $match->id,
                        'sport_type' => $match->sport_type,
                        'title' => $match->title,
                        'location' => $match->location,
                    ]
                );
            } catch (\Exception $e) {
                Log::error('Activity feed failed: ' . $e->getMessage());
            }

            return ['match' => $match->load('users:id,name,profile_picture')];
        });
    }
}
