<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FollowTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_follow_another_user()
    {
        $follower = User::factory()->create();
        $followed = User::factory()->create();

        $response = $this->actingAs($follower, 'sanctum')
            ->postJson("/api/users/{$followed->id}/follow");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'isFollowed' => true,
                'followersCount' => 1
            ]);

        $this->assertDatabaseHas('follows', [
            'follower_id' => $follower->id,
            'followed_id' => $followed->id,
        ]);

        $this->assertEquals(1, $followed->followers()->count());
        $this->assertEquals(1, $follower->following()->count());
    }

    public function test_user_can_unfollow_another_user()
    {
        $follower = User::factory()->create();
        $followed = User::factory()->create();

        // Follow first
        $follower->following()->attach($followed->id);

        $response = $this->actingAs($follower, 'sanctum')
            ->postJson("/api/users/{$followed->id}/unfollow");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'isFollowed' => false,
                'followersCount' => 0
            ]);

        $this->assertDatabaseMissing('follows', [
            'follower_id' => $follower->id,
            'followed_id' => $followed->id,
        ]);
    }

    public function test_user_cannot_follow_themselves()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/users/{$user->id}/follow");

        $response->assertStatus(422)
            ->assertJson([
                'message' => 'You cannot follow yourself'
            ]);
    }

    public function test_profile_contains_follow_stats_and_is_followed_state()
    {
        $follower = User::factory()->create();
        $followed = User::factory()->create();

        $follower->following()->attach($followed->id);

        // Fetch followed user profile as follower
        $response = $this->actingAs($follower, 'sanctum')
            ->getJson("/api/users/{$followed->id}");

        $response->assertStatus(200)
            ->assertJson([
                'followersCount' => 1,
                'followingCount' => 0,
                'isFollowed' => true
            ]);

        // Fetch followed user profile as guests / non-followers
        $otherUser = User::factory()->create();
        $response2 = $this->actingAs($otherUser, 'sanctum')
            ->getJson("/api/users/{$followed->id}");

        $response2->assertStatus(200)
            ->assertJson([
                'followersCount' => 1,
                'followingCount' => 0,
                'isFollowed' => false
            ]);
    }
}
