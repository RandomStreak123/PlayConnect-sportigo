<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Ensure target columns exist
        if (!Schema::hasColumn('users', 'avatar')) {
            Schema::table('users', function (Blueprint $table) {
                $table->text('avatar')->nullable()->after('password');
            });
        }
        if (!Schema::hasColumn('users', 'phone_number')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('phone_number')->nullable()->after('hide_phone');
            });
        }

        // 2. Data Migration: Copy data from redundant columns to target columns if not empty
        if (Schema::hasColumn('users', 'profile_picture')) {
            DB::table('users')->whereNull('avatar')->whereNotNull('profile_picture')->update([
                'avatar' => DB::raw('profile_picture')
            ]);
        }
        if (Schema::hasColumn('users', 'profile_photo')) {
            DB::table('users')->whereNull('avatar')->whereNotNull('profile_photo')->update([
                'avatar' => DB::raw('profile_photo')
            ]);
        }
        if (Schema::hasColumn('users', 'phone')) {
            DB::table('users')->whereNull('phone_number')->whereNotNull('phone')->update([
                'phone_number' => DB::raw('phone')
            ]);
        }

        // 3. Drop redundant columns from users
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'profile_picture')) {
                $table->dropColumn('profile_picture');
            }
            if (Schema::hasColumn('users', 'profile_photo')) {
                $table->dropColumn('profile_photo');
            }
            if (Schema::hasColumn('users', 'phone')) {
                $table->dropColumn('phone');
            }
        });

        // 4. Unify coordinate precision to decimal(10,7) in users
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'latitude')) {
                $table->decimal('latitude', 10, 7)->change()->nullable();
            }
            if (Schema::hasColumn('users', 'longitude')) {
                $table->decimal('longitude', 10, 7)->change()->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Restore latitude/longitude column types
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'latitude')) {
                $table->decimal('latitude', 10, 8)->change()->nullable();
            }
            if (Schema::hasColumn('users', 'longitude')) {
                $table->decimal('longitude', 11, 8)->change()->nullable();
            }
        });

        // Recreate dropped columns
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'profile_picture')) {
                $table->text('profile_picture')->nullable();
            }
            if (!Schema::hasColumn('users', 'profile_photo')) {
                $table->text('profile_photo')->nullable();
            }
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone')->nullable();
            }
        });
    }
};
