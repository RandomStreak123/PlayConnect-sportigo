<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MatchController;

// Public routes – throttled at 10/min per IP (brute-force protection)
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:auth');
Route::post('/login',    [AuthController::class, 'login'])->middleware('throttle:auth');

// Protected routes
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/profile/photo', [\App\Http\Controllers\API\ProfileController::class, 'uploadProfilePhoto']);
    Route::put('/profile',        [\App\Http\Controllers\API\ProfileController::class, 'updateProfile']);

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
    });
});
