<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sport_match_user', function (Blueprint $table) {
            $table->unique(['user_id', 'sport_match_id']);
        });
    }

    public function down(): void
    {
        Schema::table('sport_match_user', function (Blueprint $table) {
            $table->dropUnique(['user_id', 'sport_match_id']);
        });
    }
};
