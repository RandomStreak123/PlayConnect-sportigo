<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InstagramAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_instagram_login_fails_with_invalid_state()
    {
        $response = $this->postJson('/api/auth/instagram', [
            'code' => 'test_code',
            'state' => 'invalid_state',
            'redirect_uri' => 'https://localhost:5173/instagram-callback'
        ]);

        $response->assertStatus(403)
                 ->assertJsonFragment(['message' => 'Invalid state parameter. Possible CSRF attack.']);
    }

    public function test_instagram_login_success()
    {
        Cache::put('instagram_state_valid_state', true, 600);

        Http::fake([
            'https://api.instagram.com/oauth/access_token' => Http::response([
                'access_token' => 'mocked_instagram_token',
                'user_id' => 123456789
            ], 200),
            'https://graph.instagram.com/me*' => Http::response([
                'id' => '123456789',
                'username' => 'test_instagram_username',
                'profile_picture_url' => 'https://instagram.cdn/test.jpg'
            ], 200)
        ]);

        $response = $this->postJson('/api/auth/instagram', [
            'code' => 'test_code',
            'state' => 'valid_state',
            'redirect_uri' => 'https://localhost:5173/instagram-callback'
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user' => [
                         'id',
                         'username',
                         'instagram_id',
                         'auth_provider'
                     ]
                 ]);

        $this->assertDatabaseHas('users', [
            'instagram_id' => '123456789',
            'username' => 'test_instagram_username',
            'auth_provider' => 'instagram'
        ]);
    }

    public function test_link_instagram_fails_with_invalid_state()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/link/instagram', [
            'code' => 'test_code',
            'state' => 'invalid_state',
            'redirect_uri' => 'https://localhost:5173/instagram-callback'
        ]);

        $response->assertStatus(403)
                 ->assertJsonFragment(['message' => 'Invalid state parameter. Possible CSRF attack.']);
    }

    public function test_link_instagram_success()
    {
        $user = User::factory()->create();
        Cache::put('instagram_state_valid_state', true, 600);

        Http::fake([
            'https://api.instagram.com/oauth/access_token' => Http::response([
                'access_token' => 'mocked_instagram_token',
                'user_id' => 123456789
            ], 200),
            'https://graph.instagram.com/me*' => Http::response([
                'id' => '123456789',
                'username' => 'test_instagram_username',
                'profile_picture_url' => 'https://instagram.cdn/test.jpg'
            ], 200)
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/link/instagram', [
            'code' => 'test_code',
            'state' => 'valid_state',
            'redirect_uri' => 'https://localhost:5173/instagram-callback'
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user' => [
                         'id',
                         'username',
                         'instagram_id',
                         'auth_provider'
                     ]
                 ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'instagram_id' => '123456789',
            'auth_provider' => 'instagram'
        ]);
    }

    public function test_link_instagram_fails_if_already_linked_to_another_user()
    {
        User::factory()->create([
            'instagram_id' => '123456789',
            'auth_provider' => 'instagram'
        ]);

        $currentUser = User::factory()->create();
        Cache::put('instagram_state_valid_state', true, 600);

        Http::fake([
            'https://api.instagram.com/oauth/access_token' => Http::response([
                'access_token' => 'mocked_instagram_token',
                'user_id' => 123456789
            ], 200),
            'https://graph.instagram.com/me*' => Http::response([
                'id' => '123456789',
                'username' => 'test_instagram_username',
                'profile_picture_url' => 'https://instagram.cdn/test.jpg'
            ], 200)
        ]);

        $response = $this->actingAs($currentUser, 'sanctum')->postJson('/api/user/link/instagram', [
            'code' => 'test_code',
            'state' => 'valid_state',
            'redirect_uri' => 'https://localhost:5173/instagram-callback'
        ]);

        $response->assertStatus(409)
                 ->assertJsonFragment(['message' => 'This Instagram account is already linked to another PlayConnect profile.']);
    }
}
