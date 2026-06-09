<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MatchController;
use App\Http\Controllers\TournamentController;

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\UserController;

Route::middleware('throttle:5,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::get('/auth/instagram/url', [AuthController::class, 'getInstagramUrl']);
    Route::post('/auth/instagram', [AuthController::class, 'instagramLogin']);
});

Route::get('/migrate', function () {
    \Illuminate\Support\Facades\Artisan::call('optimize:clear');
    \Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
    return response()->json(['message' => 'Database migrated successfully!', 'output' => \Illuminate\Support\Facades\Artisan::output()]);
});

Route::get('/tables', function () {
    $tables = \Illuminate\Support\Facades\DB::select('SHOW TABLES');
    return response()->json($tables);
});

Route::middleware('auth:sanctum')->group(function () {
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

    Route::get('/matches', [MatchController::class, 'index']);
    Route::get('/matches/{match}', [MatchController::class, 'show']);
    Route::post('/matches', [MatchController::class, 'store']);
    Route::put('/matches/{match}', [MatchController::class, 'update']);
    Route::delete('/matches/{match}', [MatchController::class, 'destroy']);
    Route::post('/matches/{match}/join', [MatchController::class, 'join']);
    Route::post('/matches/{match}/leave', [MatchController::class, 'leave']);
    
    Route::get('/tournaments', [TournamentController::class, 'index']);
    Route::post('/tournaments', [TournamentController::class, 'store']);
    Route::put('/tournaments/{id}', [TournamentController::class, 'update']);
    Route::post('/tournaments/{id}/register', [TournamentController::class, 'register']);
    Route::post('/tournaments/{id}/match', [TournamentController::class, 'reportScore']);
    Route::get('/tournaments/{id}/standings', [TournamentController::class, 'standings']);
    
    Route::post('/logout', [AuthController::class, 'logout']);
    
    Route::apiResource('activities', ActivityController::class)->only(['index', 'store', 'update']);

    // Storage Synchronizer
    Route::post('/storage/sync-get', [\App\Http\Controllers\StorageSyncController::class, 'get']);
    Route::post('/storage/sync-set', [\App\Http\Controllers\StorageSyncController::class, 'set']);
});

