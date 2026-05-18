<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MatchController;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    
    Route::post('/profile/photo', [\App\Http\Controllers\API\ProfileController::class, 'uploadProfilePhoto']);
    Route::apiResource('matches', MatchController::class);
    Route::post('/matches/{match}/join', [MatchController::class, 'join']);
    Route::post('/matches/{match}/leave', [MatchController::class, 'leave']);
});
