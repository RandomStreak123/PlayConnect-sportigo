<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->index('sport_type');
            $table->index('skill_level');
            $table->index('date_time');
            $table->index('women_only');
        });
    }

    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->dropIndex(['sport_type']);
            $table->dropIndex(['skill_level']);
            $table->dropIndex(['date_time']);
            $table->dropIndex(['women_only']);
        });
    }
};
