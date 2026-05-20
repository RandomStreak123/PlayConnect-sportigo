<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->boolean('women_only')->default(false)->after('skill_level');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->dropColumn('women_only');
        });
    }
};
