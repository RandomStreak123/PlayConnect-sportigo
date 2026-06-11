<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MatchController;

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\UserController;

Route::middleware('throttle:5,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/auth/google', [AuthController::class, 'googleLogin']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/migrate', function () {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        \Illuminate\Support\Facades\Artisan::call('optimize:clear');
        \Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
        return response()->json(['message' => 'Database migrated successfully!', 'output' => \Illuminate\Support\Facades\Artisan::output()]);
    });

    Route::get('/tables', function () {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $tables = \Illuminate\Support\Facades\DB::select('SHOW TABLES');
        return response()->json($tables);
    });

    Route::get('/user', [UserController::class, 'show']);
    Route::post('/user/update', [UserController::class, 'update']);
    Route::put('/user', [UserController::class, 'update']);
    
    // User Match History
    Route::get('/user/matches', [MatchController::class, 'userMatches']);

    Route::get('/users', function () {
        return \App\Models\User::select('id', 'name', 'email', 'avatar', 'primary_sport', 'skill_tier')->get();
    });
    
    // Public User Profile
    Route::get('/users/{id}', [UserController::class, 'publicProfile']);
    Route::get('/users/{id}/followers', [UserController::class, 'followers']);
    Route::get('/users/{id}/following', [UserController::class, 'following']);
    Route::post('/users/{id}/follow', [UserController::class, 'follow']);
    Route::post('/users/{id}/unfollow', [UserController::class, 'unfollow']);

    Route::post('/logout', [AuthController::class, 'logout']);
    
    Route::apiResource('activities', ActivityController::class)->only(['index', 'store', 'update']);

    // Slots
    Route::get('/slots', [\App\Http\Controllers\SlotController::class, 'index']);
    Route::put('/slots/update', [\App\Http\Controllers\SlotController::class, 'update']);

    // Storage Synchronizer
    Route::post('/storage/sync-get', [\App\Http\Controllers\StorageSyncController::class, 'get']);
    Route::post('/storage/sync-set', [\App\Http\Controllers\StorageSyncController::class, 'set']);

    Route::post('/profile/photo', [\App\Http\Controllers\API\ProfileController::class, 'uploadProfilePhoto']);
    Route::put('/profile',        [\App\Http\Controllers\API\ProfileController::class, 'updateProfile']);
    Route::get('/players',        [\App\Http\Controllers\API\ProfileController::class, 'players']);
    Route::get('/activities',     [\App\Http\Controllers\API\ActivityController::class, 'index']);
    Route::get('/notifications',  [\App\Http\Controllers\API\NotificationController::class, 'index']);
    Route::put('/notifications/read-all', [\App\Http\Controllers\API\NotificationController::class, 'markAllAsRead']);
    Route::put('/notifications/{notification}/read', [\App\Http\Controllers\API\NotificationController::class, 'markAsRead']);

    // Match reads (covered by the outer throttle:api — 60/min)
    Route::get('/matches/mine',        [MatchController::class, 'mine']);
    Route::get('/matches',             [MatchController::class, 'index']);
    Route::get('/matches/{match}',     [MatchController::class, 'show']);

    // Match write actions — stricter throttle: 20/min per user
    Route::middleware('throttle:match-actions')->group(function () {
        Route::post('/matches',                   [MatchController::class, 'store']);
        Route::put('/matches/{match}',            [MatchController::class, 'update']);
        Route::delete('/matches/{match}',         [MatchController::class, 'destroy']);
        Route::post('/matches/{match}/join',      [MatchController::class, 'join']);
        Route::post('/matches/{match}/leave',     [MatchController::class, 'leave']);
        Route::post('/matches/{match}/result',    [MatchController::class, 'recordResults']);
        Route::post('/matches/{match}/ratings',   [MatchController::class, 'submitRatings']);
        Route::get('/matches/{match}/ratings',    [MatchController::class, 'getRatings']);
    });
});

