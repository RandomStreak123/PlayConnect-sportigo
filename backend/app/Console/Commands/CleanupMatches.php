<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\SportsMatch;
use Carbon\Carbon;

class CleanupMatches extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:cleanup-matches';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Cleanup matches older than 360 hours';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $now = Carbon::now();
        $matches = SportsMatch::all();
        $deletedCount = 0;
        
        foreach ($matches as $match) {
            try {
                $matchDate = Carbon::parse($match->date);
                if ($matchDate->isPast() && $matchDate->diffInHours($now, false) > 360) {
                    $match->delete();
                    $deletedCount++;
                }
            } catch (\Exception $e) {
                // Ignore parsing errors for individual matches
            }
        }
        
        $this->info("Successfully deleted {$deletedCount} old matches.");
    }
}
