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
            $table->integer('total_slots')->nullable()->after('location');
            $table->integer('filled_slots')->default(0)->after('total_slots');
            $table->integer('remaining_slots')->default(0)->after('filled_slots');
            $table->enum('status', ['open', 'full'])->default('open')->after('remaining_slots');
        });

        // Backfill existing matches
        DB::table('sport_matches')->orderBy('id')->chunk(100, function ($matches) {
            foreach ($matches as $match) {
                $joined = DB::table('sport_match_user')
                    ->where('sport_match_id', $match->id)
                    ->count();

                $total = $match->max_slots ?? max($joined, ($match->available_slots ?? 0) + $joined);
                $filled = $joined;
                $remaining = max(0, $total - $filled);

                DB::table('sport_matches')
                    ->where('id', $match->id)
                    ->update([
                        'total_slots' => $total,
                        'filled_slots' => $filled,
                        'remaining_slots' => $remaining,
                        'status' => $remaining > 0 ? 'open' : 'full',
                    ]);
            }
        });
    }

    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->dropColumn(['total_slots', 'filled_slots', 'remaining_slots', 'status']);
        });
    }
};
