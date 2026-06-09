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
        Schema::table('sport_match_user', function (Blueprint $table) {
            $table->string('result', 10)->nullable()->default(null)->after('sport_match_id');
            // result: 'win', 'loss', 'draw', or null (not yet recorded)
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sport_match_user', function (Blueprint $table) {
            $table->dropColumn('result');
        });
    }
};
