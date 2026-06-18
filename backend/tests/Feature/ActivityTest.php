<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Activity;
use App\Models\SportsMatch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ActivityTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_retrieve_activities()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        // 1. A match organized by this user
        $match = SportsMatch::factory()->create(['creator_id' => $user->id]);

        // 2. An activity: other user joined this match
        Activity::create([
            'user_id' => $otherUser->id,
            'type' => 'match_joined',
            'message' => "{$otherUser->name} joined your match",
            'meta' => ['match_id' => $match->id, 'sport_type' => $match->sport_type, 'title' => $match->title]
        ]);

        // 3. An activity: other user left this match
        Activity::create([
            'user_id' => $otherUser->id,
            'type' => 'match_left',
            'message' => "{$otherUser->name} left your match",
            'meta' => ['match_id' => $match->id, 'sport_type' => $match->sport_type, 'title' => $match->title]
        ]);

        // 4. An activity: other user created a match (should not show)
        Activity::create([
            'user_id' => $otherUser->id,
            'type' => 'match_created',
            'message' => "{$otherUser->name} created a match",
            'meta' => ['match_id' => 999, 'sport_type' => 'Football', 'title' => 'Friendly Football']
        ]);

        // 5. An activity: this user created a match (should not show)
        Activity::create([
            'user_id' => $user->id,
            'type' => 'match_created',
            'message' => "{$user->name} created a match",
            'meta' => ['match_id' => $match->id, 'sport_type' => $match->sport_type, 'title' => $match->title]
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/activities');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(2, $data);
        
        $messages = collect($data)->pluck('message');
        $this->assertTrue($messages->contains("{$otherUser->name} joined your match"));
        $this->assertTrue($messages->contains("{$otherUser->name} left your match"));
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
