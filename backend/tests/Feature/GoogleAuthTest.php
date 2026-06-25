<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class GoogleAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_google_login_requires_credential()
    {
        $response = $this->postJson('/api/auth/google', []);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['credential']);
    }

    public function test_google_login_fails_with_invalid_credential()
    {
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([], 400),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'credential' => 'invalid-token',
        ]);

        $response->assertStatus(401)
                 ->assertJson(['message' => 'Invalid Google credential']);
    }

    public function test_google_login_registers_new_user()
    {
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-id-123',
                'email' => 'messi@example.com',
                'email_verified' => true,
                'name' => 'Lionel Messi',
                'picture' => 'https://example.com/avatar.jpg',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'credential' => 'valid-token',
        ]);

        $response->assertStatus(404)
                 ->assertJson(['message' => 'No user found']);

        $this->assertDatabaseMissing('users', [
            'email' => 'messi@example.com',
        ]);
    }

    public function test_google_login_resolves_duplicate_username()
    {
        // Pre-create user with username "messi"
        User::factory()->create([
            'username' => 'messi',
            'email' => 'other@example.com',
        ]);

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-id-123',
                'email' => 'messi@example.com',
                'email_verified' => true,
                'name' => 'Lionel Messi',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'credential' => 'valid-token',
        ]);

        $response->assertStatus(404)
                 ->assertJson(['message' => 'No user found']);

        $this->assertDatabaseMissing('users', [
            'email' => 'messi@example.com',
        ]);
    }

    public function test_google_login_links_existing_user_by_email()
    {
        $existingUser = User::factory()->create([
            'email' => 'messi@example.com',
            'username' => 'messi',
            'google_id' => null,
        ]);

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-id-123',
                'email' => 'messi@example.com',
                'email_verified' => true,
                'name' => 'Lionel Messi',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'credential' => 'valid-token',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $existingUser->id,
            'google_id' => 'google-id-123',
        ]);
    }

    public function test_google_login_logs_in_existing_google_user()
    {
        $existingUser = User::factory()->create([
            'email' => 'messi@example.com',
            'username' => 'messi',
            'google_id' => 'google-id-123',
        ]);

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-id-123',
                'email' => 'messi@example.com',
                'email_verified' => true,
                'name' => 'Lionel Messi',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'credential' => 'valid-token',
        ]);

        $response->assertStatus(200);
        $this->assertEquals($existingUser->id, $response->json('user.id'));
    }
}
