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
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['instagram_id']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['instagram_id', 'auth_provider']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('instagram_id', 100)->nullable()->unique();
            $table->string('auth_provider', 50)->nullable();
        });
    }
};
