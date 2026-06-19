<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Lionel Messi',
            'username' => 'messi',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user' => ['id', 'username']
                 ]);

        $this->assertDatabaseHas('users', [
            'username' => 'messi',
        ]);
    }

    public function test_user_cannot_register_with_short_password()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Lionel Messi',
            'username' => 'messi',
            'password' => '123',
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['password']);
    }

    public function test_user_can_login()
    {
        $user = User::factory()->create([
            'username' => 'ronaldo',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/login', [
            'username' => 'ronaldo',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user'
                 ]);
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        $user = User::factory()->create([
            'username' => 'ronaldo',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/login', [
            'username' => 'ronaldo',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
                 ->assertJson([
                     'message' => 'Invalid login details'
                 ]);
    }

    public function test_user_can_logout()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test_token')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
        ])->postJson('/api/logout');

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Successfully logged out'
                 ]);
    }

    public function test_login_revokes_previous_tokens()
    {
        $user = User::factory()->create([
            'username' => 'neymar',
            'password' => Hash::make('password123'),
        ]);

        // Create initial token (e.g. from first device)
        $token1 = $user->createToken('first_device')->plainTextToken;
        $this->assertEquals(1, $user->tokens()->count());

        // Login again (e.g. from second device)
        $response = $this->postJson('/api/login', [
            'username' => 'neymar',
            'password' => 'password123',
        ]);

        $response->assertStatus(200);

        // Verify that the first token is deleted and only the new token remains
        $this->assertEquals(1, $user->tokens()->count());
        
        // Try accessing an authenticated endpoint with the old token
        $userJson = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token1,
        ])->getJson('/api/user');
        
        $userJson->assertStatus(401);
    }
}
