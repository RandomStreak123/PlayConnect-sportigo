<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Tournament;
use App\Models\TournamentMatch;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TournamentTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_retrieve_tournaments()
    {
        $user = User::factory()->create();
        Tournament::create([
            'title' => 'Championship Cup',
            'category' => 'Football',
            'description' => 'The ultimate football tournament',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 16,
            'registered_teams' => 0,
            'status' => 'open',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/tournaments');

        $response->assertStatus(200)
                 ->assertJsonCount(1)
                 ->assertJsonFragment(['title' => 'Championship Cup']);
    }

    public function test_can_create_tournament()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/tournaments', [
            'title' => 'Summer Slam',
            'category' => 'Tennis',
            'description' => 'Outdoor tennis championship',
            'start_date' => Carbon::now()->addDays(10)->toDateString(),
            'fee' => 25.0,
            'max_teams' => 8,
            'prize_pool' => '500 USD',
            'format' => 'Single Elimination',
            'organizer' => 'Sportigo Club',
        ]);

        $response->assertStatus(201)
                 ->assertJsonFragment(['title' => 'Summer Slam']);

        $this->assertDatabaseHas('tournaments', [
            'title' => 'Summer Slam',
            'category' => 'Tennis',
            'status' => 'open',
        ]);
    }

    public function test_can_update_tournament()
    {
        $user = User::factory()->create();
        $tournament = Tournament::create([
            'title' => 'Old Tournament',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 16,
            'registered_teams' => 0,
            'status' => 'open',
        ]);

        $response = $this->actingAs($user, 'sanctum')->putJson("/api/tournaments/{$tournament->id}", [
            'title' => 'Updated Tournament',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 60.0,
            'max_teams' => 12,
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment(['title' => 'Updated Tournament']);

        $this->assertDatabaseHas('tournaments', [
            'id' => $tournament->id,
            'title' => 'Updated Tournament',
            'fee' => 60.0,
            'max_teams' => 12,
        ]);
    }

    public function test_user_can_register_for_tournament()
    {
        $user = User::factory()->create(['name' => 'John Doe']);
        $tournament = Tournament::create([
            'title' => 'Championship Cup',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 16,
            'registered_teams' => 0,
            'status' => 'open',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/tournaments/{$tournament->id}/register", [
            'team_name' => 'Red Devils'
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment(['message' => 'Successfully registered for Championship Cup!']);

        $this->assertDatabaseHas('tournament_user', [
            'user_id' => $user->id,
            'tournament_id' => $tournament->id,
            'team_name' => 'Red Devils'
        ]);

        $this->assertEquals(1, $tournament->fresh()->registered_teams);
    }

    public function test_user_cannot_register_twice_for_same_tournament()
    {
        $user = User::factory()->create();
        $tournament = Tournament::create([
            'title' => 'Championship Cup',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 16,
            'registered_teams' => 0,
            'status' => 'open',
        ]);

        // Register first time
        $tournament->participants()->attach($user->id, ['team_name' => 'Team A']);
        $tournament->increment('registered_teams');

        // Try registering second time
        $response = $this->actingAs($user, 'sanctum')->postJson("/api/tournaments/{$tournament->id}/register", [
            'team_name' => 'Team B'
        ]);

        $response->assertStatus(400)
                 ->assertJsonFragment(['message' => 'You are already registered for this tournament.']);
    }

    public function test_cannot_register_if_tournament_is_full()
    {
        $user = User::factory()->create();
        $tournament = Tournament::create([
            'title' => 'Championship Cup',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 2,
            'registered_teams' => 2,
            'status' => 'open',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/tournaments/{$tournament->id}/register");

        $response->assertStatus(422)
                 ->assertJsonFragment(['message' => 'Tournament is already full.']);
    }

    public function test_can_report_score_and_retrieve_standings()
    {
        $user = User::factory()->create();
        $tournament = Tournament::create([
            'title' => 'Championship Cup',
            'category' => 'Football',
            'start_date' => Carbon::now()->addDays(5)->toDateString(),
            'fee' => 50.0,
            'max_teams' => 16,
            'registered_teams' => 0,
            'status' => 'open',
        ]);

        // Report first match: Team A 3 - 1 Team B
        $response1 = $this->actingAs($user, 'sanctum')->postJson("/api/tournaments/{$tournament->id}/match", [
            't1_name' => 'Team A',
            't2_name' => 'Team B',
            't1_score' => 3,
            't2_score' => 1,
            'round' => 1,
        ]);
        $response1->assertStatus(200);

        // Report second match: Team B 2 - 2 Team C
        $response2 = $this->actingAs($user, 'sanctum')->postJson("/api/tournaments/{$tournament->id}/match", [
            't1_name' => 'Team B',
            't2_name' => 'Team C',
            't1_score' => 2,
            't2_score' => 2,
            'round' => 1,
        ]);
        $response2->assertStatus(200);

        // Retrieve standings
        $standingsResponse = $this->actingAs($user, 'sanctum')->getJson("/api/tournaments/{$tournament->id}/standings");
        $standingsResponse->assertStatus(200);

        $standings = $standingsResponse->json();

        // Team A: 1 played, 1 won, 3 points. Rank 1.
        // Team C: 1 played, 0 won, 1 points (draw). Rank 2.
        // Team B: 2 played, 0 won, 1 points (draw, 1 lost). Rank 3 (points tied with C, but C has better goal/stats or sorted by PHP usort).
        $this->assertEquals('Team A', $standings[0]['name']);
        $this->assertEquals(3, $standings[0]['points']);
        $this->assertEquals(1, $standings[0]['rank']);

        $this->assertEquals(1, $standings[1]['points']);
        $this->assertEquals(2, $standings[1]['rank']);
    }
}
