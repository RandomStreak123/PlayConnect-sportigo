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
            $table->dropColumn(['total_slots', 'filled_slots', 'remaining_slots']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sport_matches', function (Blueprint $table) {
            $table->integer('total_slots')->nullable();
            $table->integer('filled_slots')->nullable();
            $table->integer('remaining_slots')->nullable();
        });
    }
};
