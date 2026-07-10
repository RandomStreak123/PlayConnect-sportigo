<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Auth endpoints: 30 attempts per minute per IP
        RateLimiter::for('auth', function (Request $request) {
            if (app()->environment('testing')) {
                return Limit::none();
            }
            return Limit::perMinute(30)->by($request->ip());
        });

        // General API reads: 60 requests per minute per authenticated user (falls back to IP)
        RateLimiter::for('api', function (Request $request) {
            if (app()->environment('testing')) {
                return Limit::none();
            }
            return Limit::perMinute(60)
                ->by($request->user()?->id ?: $request->ip());
        });

        // Write/action endpoints (join, leave, create): 20 per minute per user
        RateLimiter::for('match-actions', function (Request $request) {
            if (app()->environment('testing')) {
                return Limit::none();
            }
            return Limit::perMinute(20)
                ->by($request->user()?->id ?: $request->ip());
        });
    }
}
