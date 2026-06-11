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

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user->append('stats'),
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

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user->append('stats'),
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
        $request->validate([
            'credential' => 'required|string',
        ]);

        $credential = $request->credential;
        \Illuminate\Support\Facades\Log::info('Google login initiated', ['token_length' => strlen($credential)]);

        try {
            $response = \Illuminate\Support\Facades\Http::withoutVerifying()->get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $credential,
            ]);

            \Illuminate\Support\Facades\Log::info('Google tokeninfo response status: ' . $response->status());

            $payload = null;
            if ($response->successful()) {
                $payload = $response->json();
                \Illuminate\Support\Facades\Log::info('Google tokeninfo verified successfully via API', ['payload_keys' => array_keys($payload)]);
            } else {
                \Illuminate\Support\Facades\Log::warning('Google tokeninfo verification failed', ['response_body' => $response->body()]);
                if (config('app.env') === 'local') {
                    // Local fallback: decode JWT token payload without signature verification
                    \Illuminate\Support\Facades\Log::info('Using local JWT payload decode fallback');
                    $parts = explode('.', $credential);
                    if (count($parts) === 3) {
                        $payloadJson = base64_decode(strtr($parts[1], '-_', '+/'));
                        $payload = json_decode($payloadJson, true);
                    }
                }
            }

            if (!$payload) {
                \Illuminate\Support\Facades\Log::error('Google login failed: Decoded payload is null');
                return response()->json(['message' => 'Invalid Google credential (empty payload)'], 401);
            }

            \Illuminate\Support\Facades\Log::info('Google payload details', [
                'sub' => $payload['sub'] ?? 'missing',
                'email' => $payload['email'] ?? 'missing',
                'email_verified' => $payload['email_verified'] ?? 'missing',
                'aud' => $payload['aud'] ?? 'missing',
            ]);

            if (!isset($payload['sub']) || !isset($payload['email'])) {
                return response()->json(['message' => 'Invalid Google credential (sub or email missing)'], 401);
            }

            // Check email verification if provided
            if (isset($payload['email_verified']) && $payload['email_verified'] !== 'true' && $payload['email_verified'] !== true) {
                if (config('app.env') !== 'local') {
                    \Illuminate\Support\Facades\Log::warning('Email verification check failed');
                    return response()->json(['message' => 'Google email not verified'], 401);
                }
            }

            // Validate client ID (aud) if configured
            $configuredClientId = config('services.google.client_id');
            \Illuminate\Support\Facades\Log::info('Client ID validation', [
                'configured' => $configuredClientId,
                'payload_aud' => $payload['aud'] ?? null
            ]);
            if ($configuredClientId && isset($payload['aud']) && $payload['aud'] !== $configuredClientId) {
                if (config('app.env') !== 'local') {
                    \Illuminate\Support\Facades\Log::error('Client ID mismatch');
                    return response()->json(['message' => 'Unrecognized Google Client ID'], 401);
                }
            }

            $googleId = $payload['sub'];
            $email = $payload['email'];
            $name = $payload['name'] ?? 'Google User';
            $picture = $payload['picture'] ?? null;

            // 1. Try to find user by google_id
            $user = User::where('google_id', $googleId)->first();
            \Illuminate\Support\Facades\Log::info('Find user by google_id query', ['found' => !is_null($user)]);

            if (!$user) {
                // 2. Try to find user by email
                $user = User::where('email', $email)->first();
                \Illuminate\Support\Facades\Log::info('Find user by email query', ['email' => $email, 'found' => !is_null($user)]);

                if ($user) {
                    // Update user's google_id if not set
                    $user->google_id = $googleId;
                    if (!$user->avatar && $picture) {
                        $user->avatar = $picture;
                    }
                    $user->save();
                    \Illuminate\Support\Facades\Log::info('Associated user successfully', ['user_id' => $user->id]);
                } else {
                    // Do not auto-create a new user. Return unauthorized.
                    return response()->json([
                        'message' => 'This Google account is not associated with any registered user. Please add this email to your profile first.'
                    ], 401);
                }
            }

            // Revoke other tokens and create new one
            $user->tokens()->delete();
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user->append('stats'),
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Authentication failed: ' . $e->getMessage()], 500);
        }
    }
}
