<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\SportsMatch;
use App\Models\Notification;
use Carbon\Carbon;

class SendMatchReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:send-match-reminders';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send notifications to match participants 1 hour before start';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Find matches starting between 50 and 70 minutes from now
        $startTime = Carbon::now()->addMinutes(50);
        $endTime = Carbon::now()->addMinutes(70);

        $matches = SportsMatch::with('participants')
            ->whereBetween('date_time', [$startTime, $endTime])
            ->get();

        $sentCount = 0;

        foreach ($matches as $match) {
            foreach ($match->participants as $user) {
                // Check if a reminder for this match was already created for this user
                $exists = Notification::where('user_id', $user->id)
                    ->where('type', 'match_reminder')
                    ->where('meta->match_id', $match->id)
                    ->exists();

                if (!$exists) {
                    Notification::create([
                        'user_id' => $user->id,
                        'type' => 'match_reminder',
                        'title' => 'Match Starting Soon ⚽',
                        'message' => "Your match \"{$match->title}\" at {$match->location} starts in 1 hour!",
                        'is_read' => false,
                        'meta' => [
                            'match_id' => $match->id,
                            'sport_type' => $match->sport_type,
                            'title' => $match->title,
                            'location' => $match->location,
                        ],
                    ]);
                    $sentCount++;
                }
            }
        }

        $this->info("Successfully sent {$sentCount} match reminders.");
    }
}
