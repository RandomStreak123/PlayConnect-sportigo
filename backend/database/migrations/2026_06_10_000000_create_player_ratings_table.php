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
        Schema::create('player_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('match_id');
            $table->unsignedBigInteger('rater_id'); // user giving the rating
            $table->unsignedBigInteger('rated_id'); // user being rated
            $table->tinyInteger('rating')->unsigned(); // 1-5 stars
            $table->timestamps();

            $table->unique(['match_id', 'rater_id', 'rated_id']); // one rating per pair per match
            $table->foreign('match_id')->references('id')->on('sport_matches')->onDelete('cascade');
            $table->foreign('rater_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('rated_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('player_ratings');
    }
};
