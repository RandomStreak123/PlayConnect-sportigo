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
}
