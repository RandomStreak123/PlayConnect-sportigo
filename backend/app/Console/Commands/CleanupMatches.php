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
    protected $description = 'Cleanup matches older than 12 hours';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info("Successfully deleted 0 old matches (Cleanup disabled to preserve match history).");
    }
}
