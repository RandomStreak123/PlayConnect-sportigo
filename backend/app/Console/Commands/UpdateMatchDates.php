<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class UpdateMatchDates extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:update-match-dates';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Dynamically updates match dates to keep past matches in the past and future matches in the future relative to now.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting match date updates...');

        $pastMatchUpdates = [
            9  => 5,
            10 => 6,
            11 => 4,
            12 => 8,
            13 => 7,
            14 => 6,
            23 => 3,
            24 => 5,
            30 => 12,
            32 => 11,
            10027 => 1,
        ];

        $futureMatchUpdates = [
            15 => 1,
            16 => 2,
            17 => 2,
            18 => 3,
            19 => 4,
            20 => 3,
            21 => 4,
            22 => 5,
            25 => 1,
            26 => 2,
            27 => 3,
            28 => 2,
            31 => 1,
            33 => 3,
            34 => 2,
            35 => 2,
            36 => 2,
            37 => 4,
            38 => 5,
            39 => 4,
            40 => 3,
            41 => 5,
            42 => 6,
            43 => 6,
            44 => 5,
            46 => 4,
            48 => 6,
            50 => 5,
            52 => 6,
            53 => 6,
            54 => 6,
            55 => 3,
            56 => 4,
            57 => 4,
            58 => 5,
            59 => 3,
            60 => 6,
            61 => 6,
        ];

        $now = now();
        $updatedPast = 0;
        $updatedFuture = 0;

        foreach ($pastMatchUpdates as $id => $days) {
            $affected = \DB::table('sport_matches')
                ->where('id', $id)
                ->update([
                    'date_time' => $now->copy()->subDays($days)->setTime(18, 0, 0),
                    'updated_at' => $now,
                ]);
            $updatedPast += $affected;
        }

        foreach ($futureMatchUpdates as $id => $days) {
            $affected = \DB::table('sport_matches')
                ->where('id', $id)
                ->update([
                    'date_time' => $now->copy()->addDays($days)->setTime(19, 30, 0),
                    'updated_at' => $now,
                ]);
            $updatedFuture += $affected;
        }

        $this->info("Successfully updated {$updatedPast} past matches and {$updatedFuture} upcoming matches.");
        return Command::SUCCESS;
    }
}
