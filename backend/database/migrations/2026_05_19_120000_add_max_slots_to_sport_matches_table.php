<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->unsignedInteger('max_slots')->default(1)->after('available_slots');
        });

        $matches = DB::table('sport_matches')->get();
        foreach ($matches as $match) {
            $joined = DB::table('sport_match_user')
                ->where('sport_match_id', $match->id)
                ->count();

            $maxSlots = max(1, (int) $match->available_slots + $joined);

            DB::table('sport_matches')
                ->where('id', $match->id)
                ->update([
                    'max_slots' => $maxSlots,
                    'available_slots' => max(0, $maxSlots - $joined),
                ]);
        }

        $orphans = DB::table('sport_matches')->whereNull('creator_id')->pluck('id');
        foreach ($orphans as $matchId) {
            $firstUserId = DB::table('sport_match_user')
                ->where('sport_match_id', $matchId)
                ->orderBy('id')
                ->value('user_id');

            if ($firstUserId) {
                DB::table('sport_matches')
                    ->where('id', $matchId)
                    ->update(['creator_id' => $firstUserId]);
            }
        }
    }

    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->dropColumn('max_slots');
        });
    }
};
