<?php

namespace App\Services;

use App\Models\SportsMatch;
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
    public function syncMatch(SportsMatch $match, bool $save = false): SportsMatch
    {
        $match->syncAvailableSlots($save);

        if ($save) {
            return $match->fresh(['participants:id,name,avatar']);
        }
        return $match;
    }

    public function syncCollection(Collection $matches, bool $save = false): Collection
    {
        $matches->each(fn (SportsMatch $match) => $match->syncAvailableSlots($save));

        return $matches;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function createMatch(array $validated, User $user, bool $womenOnly): SportsMatch
    {
        $maxSlots = (int) $validated['available_slots'];
        $openSlots = max(0, $maxSlots - 1);

        return DB::transaction(function () use ($validated, $womenOnly, $maxSlots, $user, $openSlots) {
            $match = SportsMatch::create([
                ...collect($validated)->except('available_slots')->all(),
                'available_slots' => $openSlots,
                'max_slots' => $maxSlots,
                'women_only' => $womenOnly,
                'creator_id' => $user->id,
            ]);

            $match->participants()->attach($user->id);
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

            return $match->load('participants:id,name,avatar');
        });
    }

    public function updateOpenSlots(SportsMatch $match, int $totalSlots): SportsMatch
    {
        return DB::transaction(function () use ($match, $totalSlots) {
            $match = SportsMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();
            $joined = $match->participants()->count();
            $openSlots = max(0, $totalSlots - $joined);
            
            $match->update([
                'available_slots' => $openSlots,
                'max_slots' => max($joined, $totalSlots),
            ]);
            $match->syncAvailableSlots();

            return $match->load('participants:id,name,avatar');
        });
    }

    /**
     * @return array{error?: string, status?: int, match?: SportsMatch}
     */
    public function join(SportsMatch $match, User $user): array
    {
        return DB::transaction(function () use ($match, $user) {
            $match = SportsMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();

            if ($match->participants()->where('user_id', $user->id)->exists()) {
                return ['error' => 'Already joined', 'status' => 409];
            }

            if ($match->participants()->count() >= $match->max_slots) {
                return ['error' => 'Match is full', 'status' => 409];
            }

            $match->participants()->attach($user->id);
            $match->syncAvailableSlots();

            // Create notification for match creator if they are not the joining user
            if ((int) $match->creator_id !== (int) $user->id) {
                try {
                    \App\Models\Notification::create([
                        'user_id' => $match->creator_id,
                        'type' => 'match_joined',
                        'title' => 'Player Joined',
                        'message' => "{$user->name} joined your {$match->sport_type} match: \"{$match->title}\".",
                        'meta' => [
                            'match_id' => $match->id,
                            'sport_type' => $match->sport_type,
                            'title' => $match->title,
                        ],
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to create join notification: ' . $e->getMessage());
                }
            }

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

            return ['match' => $match->load('participants:id,name,avatar')];
        });
    }

    /**
     * @return array{error?: string, status?: int, match?: SportsMatch}
     */
    public function leave(SportsMatch $match, User $user): array
    {
        if (! $match->participants()->where('user_id', $user->id)->exists()) {
            return ['error' => 'You are not a member of this match', 'status' => 404];
        }

        if ((int) $match->creator_id === (int) $user->id) {
            return [
                'error' => 'Match creators cannot leave. Delete the match instead.',
                'status' => 403,
            ];
        }

        return DB::transaction(function () use ($match, $user) {
            $match = SportsMatch::whereKey($match->id)->lockForUpdate()->firstOrFail();
            $match->participants()->detach($user->id);
            $match->syncAvailableSlots();

            // Create notification for match creator if they are not the leaving user
            if ((int) $match->creator_id !== (int) $user->id) {
                try {
                    \App\Models\Notification::create([
                        'user_id' => $match->creator_id,
                        'type' => 'match_left',
                        'title' => 'Player Left',
                        'message' => "{$user->name} left your {$match->sport_type} match: \"{$match->title}\".",
                        'meta' => [
                            'match_id' => $match->id,
                            'sport_type' => $match->sport_type,
                            'title' => $match->title,
                        ],
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to create leave notification: ' . $e->getMessage());
                }
            }

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

            return ['match' => $match->load('participants:id,name,avatar')];
        });
    }
}
