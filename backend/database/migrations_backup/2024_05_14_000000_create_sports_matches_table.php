<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('sport_matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('creator_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('sport_type');
            $table->string('title');
            $table->dateTime('date_time');
            $table->string('location');
            $table->enum('status', ['open', 'full'])->default('open');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->integer('available_slots');
            $table->integer('max_slots')->default(1);
            $table->string('skill_level');
            $table->boolean('women_only')->default(false);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('sport_matches');
    }
};
