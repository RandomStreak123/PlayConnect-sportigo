<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            // Composite index for cursor pagination: ORDER BY date_time, id
            $table->index(['date_time', 'id'], 'sport_matches_cursor_idx');
        });
    }

    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->dropIndex('sport_matches_cursor_idx');
        });
    }
};
