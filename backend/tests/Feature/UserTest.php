<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_retrieve_current_user()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/user');

        $response->assertStatus(200)
                 ->assertJson([
                     'id' => $user->id,
                     'email' => $user->email,
                 ]);
    }

    public function test_can_update_user_profile()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/update', [
            'name' => 'Updated Name',
            'email' => 'updated@example.com',
            'phone' => '+1234567890',
            'bio' => 'A new custom bio',
            'primary_sport' => 'Football',
            'skill_tier' => 'Elite',
            'gender' => 'male',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
            'email' => 'updated@example.com',
            'phone' => '+1234567890',
            'bio' => 'A new custom bio',
            'primary_sport' => 'Football',
            'skill_tier' => 'Elite',
            'gender' => 'male',
        ]);
    }

    public function test_can_update_user_profile_with_null_email()
    {
        $user = User::factory()->create([
            'email' => 'old@example.com',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/update', [
            'name' => 'Updated Name',
            'email' => null,
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => null,
        ]);
    }

    public function test_can_retrieve_all_users()
    {
        $user = User::factory()->create();
        $otherUsers = User::factory()->count(2)->create();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/users');

        $response->assertStatus(200)
                 ->assertJsonCount(3);
    }

    public function test_can_retrieve_public_profile()
    {
        $user = User::factory()->create();
        $targetUser = User::factory()->create([
            'name' => 'John Doe',
            'bio' => 'Public bio',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/users/' . $targetUser->id);

        $response->assertStatus(200)
                 ->assertJson([
                     'id' => $targetUser->id,
                     'name' => 'John Doe',
                     'bio' => 'Public bio',
                 ]);
    }

    public function test_adds_email_to_profile_sends_welcome_email()
    {
        \Illuminate\Support\Facades\Mail::fake();

        $user = User::factory()->create([
            'email' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/profile', [
            'email' => 'welcome@example.com',
        ]);

        $response->assertStatus(200);

        \Illuminate\Support\Facades\Mail::assertSent(\App\Mail\WelcomeMail::class, function ($mail) {
            return $mail->hasTo('welcome@example.com');
        });
    }

    public function test_updating_existing_email_does_not_send_welcome_email()
    {
        \Illuminate\Support\Facades\Mail::fake();

        $user = User::factory()->create([
            'email' => 'old@example.com',
        ]);

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/profile', [
            'email' => 'new@example.com',
        ]);

        $response->assertStatus(200);

        \Illuminate\Support\Facades\Mail::assertNotSent(\App\Mail\WelcomeMail::class);
    }
}
