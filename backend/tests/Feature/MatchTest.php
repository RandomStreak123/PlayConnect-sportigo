<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\SportsMatch;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_retrieve_matches()
    {
        $user = User::factory()->create();
        $match = SportsMatch::create([
            'user_id' => $user->id,
            'title' => 'Tennis Match',
            'category' => 'Tennis',
            'location' => 'Court 1',
            'date' => Carbon::now()->addDays(2)->toDateTimeString(),
            'price' => '10.0',
            'status' => 'open',
            'available_slots' => 10,
            'max_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/matches');
        $response->assertStatus(200);
        if ($response->json('data') !== null) {
            $this->assertCount(1, $response->json('data'));
        } else {
            $response->assertJsonCount(1);
        }
    }

    public function test_can_create_match()
    {
        $user = User::factory()->create([
            'gender' => 'male',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/matches', [
            'title' => 'Friendly Football',
            'sport_type' => 'Football',
            'location' => 'Turf A',
            'date_time' => Carbon::now()->addDays(1)->toDateTimeString(),
            'available_slots' => 10,
            'skill_level' => 'Intermediate',
            'women_only' => false,
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('sport_matches', [
            'title' => 'Friendly Football',
            'creator_id' => $user->id,
        ]);
    }

    public function test_cannot_create_match_in_past()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/matches', [
            'title' => 'Past Match',
            'sport_type' => 'Football',
            'location' => 'Turf A',
            'date_time' => Carbon::now()->subDays(2)->toDateTimeString(),
            'available_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $response->assertStatus(422)
                 ->assertJson([
                     'message' => 'Cannot create a match in the past. Please select today or a future date/time.'
                 ]);
    }

    public function test_user_can_join_match()
    {
        $creator = User::factory()->create();
        $user = User::factory()->create([
            'gender' => 'male',
        ]);

        $match = SportsMatch::create([
            'user_id' => $creator->id,
            'title' => 'Tennis Match',
            'category' => 'Tennis',
            'location' => 'Court 1',
            'date' => Carbon::now()->addDays(2)->toDateTimeString(),
            'price' => '10.0',
            'status' => 'open',
            'is_women_only' => false,
            'available_slots' => 10,
            'max_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/matches/{$match->id}/join");

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Successfully joined the match!'
                 ]);

        $this->assertDatabaseHas('sport_match_user', [
            'user_id' => $user->id,
            'sport_match_id' => $match->id,
        ]);
    }

    public function test_men_cannot_join_women_only_match()
    {
        $creator = User::factory()->create([
            'gender' => 'female',
        ]);
        $user = User::factory()->create([
            'gender' => 'male',
        ]);

        $match = SportsMatch::create([
            'user_id' => $creator->id,
            'title' => 'Women Tennis',
            'category' => 'Tennis',
            'location' => 'Court 1',
            'date' => Carbon::now()->addDays(2)->toDateTimeString(),
            'price' => '10.0',
            'status' => 'open',
            'is_women_only' => true,
            'available_slots' => 10,
            'max_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/matches/{$match->id}/join");

        $response->assertStatus(403)
                 ->assertJson([
                     'message' => 'This match is restricted to women only.'
                 ]);
    }

    public function test_user_can_leave_match()
    {
        $creator = User::factory()->create();
        $user = User::factory()->create();

        $match = SportsMatch::create([
            'user_id' => $creator->id,
            'title' => 'Tennis Match',
            'category' => 'Tennis',
            'location' => 'Court 1',
            'date' => Carbon::now()->addDays(2)->toDateTimeString(),
            'price' => '10.0',
            'status' => 'open',
            'is_women_only' => false,
            'available_slots' => 10,
            'max_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $match->participants()->attach($user->id);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/matches/{$match->id}/leave");

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Successfully left the match!'
                 ]);

        $this->assertDatabaseMissing('sport_match_user', [
            'user_id' => $user->id,
            'sport_match_id' => $match->id,
        ]);
    }

    public function test_can_retrieve_user_matches()
    {
        $user = User::factory()->create();
        $match = SportsMatch::create([
            'user_id' => $user->id,
            'title' => 'Tennis Match',
            'category' => 'Tennis',
            'location' => 'Court 1',
            'date' => Carbon::now()->addDays(2)->toDateTimeString(),
            'price' => '10.0',
            'status' => 'open',
            'available_slots' => 10,
            'max_slots' => 10,
            'skill_level' => 'Intermediate',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/user/matches');

        $response->assertStatus(200)
                 ->assertJsonCount(1);
    }
}
