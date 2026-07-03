<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $activities = \App\Models\Activity::with('user')->whereIn('type', ['match_joined', 'match_created', 'match_left'])->get();
        foreach ($activities as $activity) {
            $user = $activity->user ? $activity->user->name : 'Someone';
            $meta = $activity->meta;
            if (!$meta || empty($meta['title'])) {
                continue;
            }
            $title = $meta['title'];
            $sportType = $meta['sport_type'] ?? 'Football';
            if ($activity->type === 'match_joined') {
                $activity->message = "{$user} joined the {$sportType} match: \"{$title}\"";
            } elseif ($activity->type === 'match_created') {
                $activity->message = "{$user} created a {$sportType} match: \"{$title}\"";
            } elseif ($activity->type === 'match_left') {
                $activity->message = "{$user} left the {$sportType} match: \"{$title}\"";
            }
            $activity->save();
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $activities = \App\Models\Activity::with('user')->whereIn('type', ['match_joined', 'match_created', 'match_left'])->get();
        foreach ($activities as $activity) {
            $user = $activity->user ? $activity->user->name : 'Someone';
            $meta = $activity->meta;
            if (!$meta) {
                continue;
            }
            $title = $meta['title'] ?? '';
            $sportType = $meta['sport_type'] ?? '';
            $location = $meta['location'] ?? '';
            if ($activity->type === 'match_joined') {
                $activity->message = "{$user} joined the {$sportType} match: \"{$title}\" at {$location}";
            } elseif ($activity->type === 'match_created') {
                $activity->message = "{$user} created a {$sportType} match: \"{$title}\" at {$location}";
            } elseif ($activity->type === 'match_left') {
                $activity->message = "{$user} left the {$sportType} match: \"{$title}\" at {$location}";
            }
            $activity->save();
        }
    }
};
