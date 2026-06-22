<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users|alpha_dash|min:3',
            'email' => 'nullable|string|email|max:255|unique:users',
            'password' => ['required', 'string', Password::min(8)],
            'phone_number' => 'nullable|string|max:20',
            'gender' => 'nullable|string|in:male,female,other',
            'role' => 'nullable|string|in:athlete,venue',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'username' => $validated['username'],
            'email' => $validated['email'] ?? null,
            'password' => Hash::make($validated['password']),
            'phone_number' => $validated['phone_number'] ?? null,
            'gender' => $validated['gender'] ?? null,
            'role' => $validated['role'] ?? 'athlete',
        ]);

        if ($user->email) {
            $frontendUrl = $request->header('Origin') ?: $request->header('Referer');
            if ($frontendUrl) {
                $frontendUrl = preg_replace('/(\/auth|\/login|\/forgot-password|\/register|\/reset-password).*$/', '', $frontendUrl);
                $frontendUrl = rtrim($frontendUrl, '/');
            } else {
                $frontendUrl = 'https://playconnect-vue.ddev.site';
            }
            try {
                \Illuminate\Support\Facades\Mail::to($user->email)->send(new \App\Mail\WelcomeMail($user->name, $frontendUrl));
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error("Failed to send welcome email on registration to {$user->email}: " . $e->getMessage());
            }
        }

        $user->append(['stats', 'followersCount', 'followingCount']);
        $token = $user->createToken('auth_token')->plainTextToken;
        $user->append('stats');

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
        ]);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', $validated['username'])
            ->orWhere('email', $validated['username'])
            ->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Invalid login details'
            ], 401);
        }

        // Revoke all existing tokens to prevent simultaneous logins
        $user->tokens()->delete();

        $user->append(['stats', 'followersCount', 'followingCount']);
        $token = $user->createToken('auth_token')->plainTextToken;
        $user->append('stats');

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Successfully logged out'
        ]);
    }

    public function googleLogin(Request $request)
    {
        if (!$request->has('credential') && $request->has('id_token')) {
            $request->merge(['credential' => $request->input('id_token')]);
        }

        $request->validate([
            'credential' => 'required|string',
        ]);

        $credential = $request->credential;

        try {
            $response = \Illuminate\Support\Facades\Http::get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $credential,
            ]);

            if ($response->failed()) {
                return response()->json(['message' => 'Invalid Google credential'], 401);
            }

            $payload = $response->json();

            if (!isset($payload['sub']) || !isset($payload['email'])) {
                return response()->json(['message' => 'Invalid token payload'], 401);
            }

            // Check email verification if provided
            if (isset($payload['email_verified']) && $payload['email_verified'] !== 'true' && $payload['email_verified'] !== true) {
                return response()->json(['message' => 'Google email not verified'], 401);
            }

            // Validate client ID (aud) if configured
            $configuredClientId = config('services.google.client_id');
            if ($configuredClientId && isset($payload['aud']) && $payload['aud'] !== $configuredClientId) {
                return response()->json(['message' => 'Unrecognized Google Client ID'], 401);
            }

            $googleId = $payload['sub'];
            $email = $payload['email'];
            $name = $payload['name'] ?? 'Google User';
            $picture = $payload['picture'] ?? null;

            // 1. Try to find user by google_id
            $user = User::where('google_id', $googleId)->first();

            if (!$user) {
                // 2. Try to find user by email
                $user = User::where('email', $email)->first();

                if ($user) {
                    // Update user's google_id if not set
                    $user->google_id = $googleId;
                    if (!$user->avatar && $picture) {
                        $user->avatar = $picture;
                    }
                    $user->save();
                } else {
                    // 3. Create a new user
                    // Generate unique username
                    $baseUsername = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', explode('@', $email)[0]));
                    if (strlen($baseUsername) < 3) {
                        $baseUsername = 'user_' . $baseUsername;
                    }
                    $username = $baseUsername;
                    $counter = 1;
                    while (User::where('username', $username)->exists()) {
                        $username = $baseUsername . $counter;
                        $counter++;
                    }

                    $user = User::create([
                        'name' => $name,
                        'username' => $username,
                        'email' => $email,
                        'google_id' => $googleId,
                        'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(24)),
                        'role' => 'athlete',
                        'avatar' => $picture,
                    ]);
                }
            }

            // Revoke other tokens and create new one
            $user->tokens()->delete();
            $user->append(['stats', 'followersCount', 'followingCount']);
            $token = $user->createToken('auth_token')->plainTextToken;
            $user->append('stats');

            return response()->json([
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user,
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Authentication failed: ' . $e->getMessage()], 500);
        }
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'username_or_email' => 'required|string',
        ]);

        $input = $request->input('username_or_email');

        $user = User::where('email', $input)
            ->orWhere('username', $input)
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'We could not find a user with that username or email address.'
            ], 404);
        }

        if (!$user->email) {
            return response()->json([
                'message' => 'This account does not have a registered email address. Please contact support.'
            ], 422);
        }

        $token = \Illuminate\Support\Str::random(64);
        
        \Illuminate\Support\Facades\DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => hash('sha256', $token),
                'created_at' => now()
            ]
        );

        // Resolve frontend URL dynamically from Origin/Referer, falling back to typical local/production URLs
        $frontendUrl = $request->header('Origin') ?: $request->header('Referer');
        if ($frontendUrl) {
            $frontendUrl = preg_replace('/(\/auth|\/login|\/forgot-password|\/register|\/reset-password).*$/', '', $frontendUrl);
            $frontendUrl = rtrim($frontendUrl, '/');
        } else {
            $frontendUrl = 'https://playconnect-vue.ddev.site';
        }

        $resetUrl = $frontendUrl . '?token=' . $token . '&email=' . urlencode($user->email);

        try {
            \Illuminate\Support\Facades\Mail::to($user->email)->send(new \App\Mail\ResetPasswordMail($resetUrl));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to send reset email. Please try again later. Error: ' . $e->getMessage()
            ], 500);
        }

        return response()->json([
            'message' => 'A password reset link has been sent to your registered email address.'
        ]);
    }

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'email' => 'required|string|email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $record = \Illuminate\Support\Facades\DB::table('password_reset_tokens')
            ->where('email', $validated['email'])
            ->first();

        if (!$record) {
            return response()->json([
                'message' => 'This password reset token is invalid.'
            ], 422);
        }

        $hashedToken = hash('sha256', $validated['token']);
        if (!hash_equals($record->token, $hashedToken)) {
            return response()->json([
                'message' => 'This password reset token is invalid.'
            ], 422);
        }

        $createdAt = \Carbon\Carbon::parse($record->created_at);
        if ($createdAt->addMinutes(60)->isPast()) {
            \Illuminate\Support\Facades\DB::table('password_reset_tokens')
                ->where('email', $validated['email'])
                ->delete();

            return response()->json([
                'message' => 'This password reset token has expired.'
            ], 422);
        }

        $user = User::where('email', $validated['email'])->first();
        if (!$user) {
            return response()->json([
                'message' => 'We could not find a user with that email address.'
            ], 404);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        \Illuminate\Support\Facades\DB::table('password_reset_tokens')
            ->where('email', $validated['email'])
            ->delete();

        return response()->json([
            'message' => 'Your password has been reset successfully! You can now log in.'
        ]);
    }
}

