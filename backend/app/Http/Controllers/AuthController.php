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

    public function getInstagramUrl()
    {
        $clientId = env('INSTAGRAM_CLIENT_ID', '');
        $redirectUri = env('INSTAGRAM_REDIRECT_URI', url('/instagram-callback'));
        
        // CSRF state protection
        $state = \Illuminate\Support\Str::random(40);
        \Illuminate\Support\Facades\Cache::put('instagram_state_' . $state, true, now()->addMinutes(10));
        
        $url = "https://api.instagram.com/oauth/authorize?client_id={$clientId}&redirect_uri=" . urlencode($redirectUri) . "&scope=instagram_basic&response_type=code&state={$state}";

        return response()->json([
            'url' => $url,
            'is_mock' => false
        ]);
    }

    public function instagramLogin(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
            'state' => 'required|string',
            'redirect_uri' => 'required|string',
        ]);

        $state = $request->state;
        if (!\Illuminate\Support\Facades\Cache::has('instagram_state_' . $state)) {
            return response()->json([
                'message' => 'Invalid state parameter. Possible CSRF attack.'
            ], 403);
        }
        \Illuminate\Support\Facades\Cache::forget('instagram_state_' . $state);

        $clientId = env('INSTAGRAM_CLIENT_ID');
        $clientSecret = env('INSTAGRAM_CLIENT_SECRET');

        try {
            // 1. Exchange code for access token
            $response = \Illuminate\Support\Facades\Http::asForm()->post('https://api.instagram.com/oauth/access_token', [
                'client_id' => $clientId,
                'client_secret' => $clientSecret,
                'grant_type' => 'authorization_code',
                'redirect_uri' => $request->redirect_uri,
                'code' => $request->code,
            ]);

            if (!$response->successful()) {
                return response()->json([
                    'message' => 'Failed to obtain access token from Instagram',
                    'details' => $response->json()
                ], 400);
            }

            $tokenData = $response->json();
            $accessToken = $tokenData['access_token'];

            // 2. Fetch user profile information (username, profile_picture_url, id)
            $profileResponse = \Illuminate\Support\Facades\Http::get("https://graph.instagram.com/me", [
                'fields' => 'id,username,profile_picture_url',
                'access_token' => $accessToken
            ]);

            if (!$profileResponse->successful()) {
                return response()->json([
                    'message' => 'Failed to retrieve Instagram user profile details',
                    'details' => $profileResponse->json()
                ], 400);
            }

            $profileData = $profileResponse->json();
            $username = $profileData['username'] ?? 'instagram_user';
            $instagramId = $profileData['id'];
            $profilePicture = $profileData['profile_picture_url'] ?? 'https://www.gravatar.com/avatar/' . md5($username) . '?d=identicon';

            // 3. Find or link user based on instagram_id or username
            $user = User::where('instagram_id', $instagramId)->first();

            if (!$user) {
                // Check if username already exists
                $user = User::where('username', $username)->first();

                if ($user) {
                    if (empty($user->instagram_id)) {
                        // Link the existing local account
                        $user->instagram_id = $instagramId;
                        $user->auth_provider = 'instagram';
                        $user->avatar = $profilePicture;
                        $user->save();
                    } else {
                        // Username is taken by another Instagram account, create a new one with unique username
                        $uniqueUsername = $username . '_' . rand(100, 999);
                        while (User::where('username', $uniqueUsername)->exists()) {
                            $uniqueUsername = $username . '_' . rand(100, 999);
                        }
                        $user = User::create([
                            'instagram_id' => $instagramId,
                            'username' => $uniqueUsername,
                            'name' => $username,
                            'avatar' => $profilePicture,
                            'auth_provider' => 'instagram',
                            'password' => Hash::make(bin2hex(random_bytes(16))),
                            'role' => 'athlete',
                        ]);
                    }
                } else {
                    // Create new user with the given username
                    $user = User::create([
                        'instagram_id' => $instagramId,
                        'username' => $username,
                        'name' => $username,
                        'avatar' => $profilePicture,
                        'auth_provider' => 'instagram',
                        'password' => Hash::make(bin2hex(random_bytes(16))),
                        'role' => 'athlete',
                    ]);
                }
            } else {
                // User already exists by instagram_id, update profile picture / username if changed
                $user->username = $username;
                $user->name = $username;
                $user->avatar = $profilePicture;
                $user->save();
            }

            // Create sanctum token
            $token = $user->createToken('auth_token')->plainTextToken;

            // Session handling: store values in secure PHP session (Laravel Session)
            session(['user_id' => $user->id, 'username' => $user->username, 'profile_picture' => $profilePicture]);

            return response()->json([
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Instagram authentication failed: ' . $e->getMessage()
            ], 500);
        }
    }

    public function linkInstagram(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
            'state' => 'required|string',
            'redirect_uri' => 'required|string',
        ]);

        $state = $request->state;
        if (!\Illuminate\Support\Facades\Cache::has('instagram_state_' . $state)) {
            return response()->json([
                'message' => 'Invalid state parameter. Possible CSRF attack.'
            ], 403);
        }
        \Illuminate\Support\Facades\Cache::forget('instagram_state_' . $state);

        $clientId = env('INSTAGRAM_CLIENT_ID');
        $clientSecret = env('INSTAGRAM_CLIENT_SECRET');

        try {
            // 1. Exchange code for access token
            $response = \Illuminate\Support\Facades\Http::asForm()->post('https://api.instagram.com/oauth/access_token', [
                'client_id' => $clientId,
                'client_secret' => $clientSecret,
                'grant_type' => 'authorization_code',
                'redirect_uri' => $request->redirect_uri,
                'code' => $request->code,
            ]);

            if (!$response->successful()) {
                return response()->json([
                    'message' => 'Failed to obtain access token from Instagram',
                    'details' => $response->json()
                ], 400);
            }

            $tokenData = $response->json();
            $accessToken = $tokenData['access_token'];

            // 2. Fetch user profile information (username, profile_picture_url, id)
            $profileResponse = \Illuminate\Support\Facades\Http::get("https://graph.instagram.com/me", [
                'fields' => 'id,username,profile_picture_url',
                'access_token' => $accessToken
            ]);

            if (!$profileResponse->successful()) {
                return response()->json([
                    'message' => 'Failed to retrieve Instagram user profile details',
                    'details' => $profileResponse->json()
                ], 400);
            }

            $profileData = $profileResponse->json();
            $username = $profileData['username'] ?? 'instagram_user';
            $instagramId = $profileData['id'];
            $profilePicture = $profileData['profile_picture_url'] ?? 'https://www.gravatar.com/avatar/' . md5($username) . '?d=identicon';

            // 3. Check if this instagram_id is already linked to ANOTHER user
            $existingLinkedUser = User::where('instagram_id', $instagramId)->where('id', '!=', $request->user()->id)->first();
            if ($existingLinkedUser) {
                return response()->json([
                    'message' => 'This Instagram account is already linked to another PlayConnect profile.'
                ], 409);
            }

            // 4. Link it to the currently authenticated user
            $user = $request->user();
            $user->instagram_id = $instagramId;
            $user->auth_provider = 'instagram';
            $user->avatar = $profilePicture; // update profile picture
            $user->save();

            // Refresh session
            session(['user_id' => $user->id, 'username' => $user->username, 'profile_picture' => $profilePicture]);

            return response()->json([
                'access_token' => $request->bearerToken() ?? $request->header('Authorization'),
                'token_type' => 'Bearer',
                'user' => $user,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Instagram account linking failed: ' . $e->getMessage()
            ], 500);
        }
    }
}
