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
    protected $description = 'Send notifications to match participants 3 hours before start';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Find matches starting between 170 and 190 minutes (approx. 3 hours) from now in local timezone (Asia/Kolkata)
        $now = Carbon::now('Asia/Kolkata');
        $startTime = $now->copy()->addMinutes(170);
        $endTime = $now->copy()->addMinutes(190);

        $matches = SportsMatch::with('participants')
            ->whereBetween('date_time', [$startTime, $endTime])
            ->get();

        $sentCount = 0;

        foreach ($matches as $match) {
            $formattedTime = Carbon::parse($match->date_time)->format('g:i A');
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
                        'title' => 'Upcoming Match Alert',
                        'message' => "You have an upcoming match: {$match->sport_type} match \"{$match->title}\" at {$match->location} scheduled for {$formattedTime}.",
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
