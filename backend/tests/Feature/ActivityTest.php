<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Activity;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ActivityTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_retrieve_activities()
    {
        $user = User::factory()->create();
        Activity::create([
            'user_id' => $user->id,
            'type' => 'match_created',
            'message' => 'John Doe created a Football match',
            'meta' => ['sport_type' => 'Football', 'title' => 'Friendly Football']
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/activities');

        $response->assertStatus(200)
                 ->assertJsonCount(1)
                 ->assertJsonFragment([
                     'message' => 'John Doe created a Football match'
                 ]);
    }

    public function test_can_create_activity()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/activities', [
            'type' => 'match_joined',
            'message' => 'John Doe joined a Tennis match',
            'meta' => ['sport_type' => 'Tennis', 'title' => 'Tennis Championship']
        ]);

        $response->assertStatus(201)
                 ->assertJsonFragment([
                     'message' => 'John Doe joined a Tennis match'
                 ]);

        $this->assertDatabaseHas('activities', [
            'user_id' => $user->id,
            'type' => 'match_joined',
            'message' => 'John Doe joined a Tennis match',
        ]);
    }

    public function test_can_update_activity()
    {
        $user = User::factory()->create();
        $activity = Activity::create([
            'user_id' => $user->id,
            'type' => 'match_created',
            'message' => 'Old message',
        ]);

        $response = $this->actingAs($user, 'sanctum')->putJson("/api/activities/{$activity->id}", [
            'message' => 'New message',
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment([
                     'message' => 'New message'
                 ]);

        $this->assertDatabaseHas('activities', [
            'id' => $activity->id,
            'message' => 'New message',
        ]);
    }
}
