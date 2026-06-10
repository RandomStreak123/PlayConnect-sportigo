<?php

namespace Tests\Feature;

use App\Models\SportsMatch;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * HTTP-level API tests for MatchController.
 *
 * These hit real routes (Sanctum auth, throttle bypassed) and assert
 * response shapes, status codes, and database state.
 */
class MatchControllerTest extends TestCase
{
    use RefreshDatabase;

    // ─── Helpers ───────────────────────────────────────────────────────────────

    private function actingAsUser(array $attrs = []): User
    {
        return User::factory()->create($attrs);
    }

    private function createMatch(User $creator, array $attrs = []): SportsMatch
    {
        $match = SportsMatch::factory()->create(array_merge(
            ['creator_id' => $creator->id],
            $attrs,
        ));
        $match->participants()->attach($creator->id);
        $match->syncAvailableSlots();

        return $match;
    }

    private function jsonHeaders(): array
    {
        return ['Accept' => 'application/json'];
    }

    // ─── Index (paginated) ─────────────────────────────────────────────────────

    /** @test */
    public function test_index_returns_paginated_json_structure(): void
    {
        $user = $this->actingAsUser();
        SportsMatch::factory()->count(3)->create();

        $response = $this->actingAs($user)
            ->getJson('/api/matches', $this->jsonHeaders());

        $response->assertOk()
            ->assertJsonStructure([
                'data'        => [['id', 'title', 'sport_type', 'available_slots', 'max_slots']],
                'next_cursor',
                'has_more',
            ]);
    }

    /** @test */
    public function test_index_filters_by_sport_type(): void
    {
        $user = $this->actingAsUser();
        SportsMatch::factory()->create(['sport_type' => 'Football']);
        SportsMatch::factory()->create(['sport_type' => 'Cricket']);

        $response = $this->actingAs($user)
            ->getJson('/api/matches?sport_type=Football', $this->jsonHeaders());

        $response->assertOk();
        $data = $response->json('data');
        $this->assertNotEmpty($data);
        foreach ($data as $match) {
            $this->assertEquals('Football', $match['sport_type']);
        }
    }

    /** @test */
    public function test_index_excludes_past_matches(): void
    {
        $user = $this->actingAsUser();
        SportsMatch::factory()->create(['date_time' => now()->subDay()]);
        SportsMatch::factory()->create(['date_time' => now()->addDay()]);

        $response = $this->actingAs($user)
            ->getJson('/api/matches', $this->jsonHeaders());

        $response->assertOk();
        // Only the future match should appear
        $this->assertCount(1, $response->json('data'));
    }

    /** @test */
    public function test_unauthenticated_user_cannot_list_matches(): void
    {
        $this->getJson('/api/matches', $this->jsonHeaders())
            ->assertUnauthorized()
            ->assertJsonStructure(['message']);
    }

    // ─── Join ──────────────────────────────────────────────────────────────────

    /** @test */
    public function test_authenticated_user_can_join_a_match(): void
    {
        $creator = $this->actingAsUser();
        $joiner  = $this->actingAsUser();
        $match   = $this->createMatch($creator, ['max_slots' => 4, 'available_slots' => 3]);

        $response = $this->actingAs($joiner)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders());

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['match' => ['id', 'available_slots', 'users']]);

        $this->assertDatabaseHas('sport_match_user', [
            'sport_match_id' => $match->id,
            'user_id'        => $joiner->id,
        ]);
    }

    /** @test */
    public function test_joining_returns_updated_slot_count(): void
    {
        $creator = $this->actingAsUser();
        $joiner  = $this->actingAsUser();
        $match   = $this->createMatch($creator, ['max_slots' => 4, 'available_slots' => 3]);

        $response = $this->actingAs($joiner)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders());

        $availableBefore = 3;
        $availableAfter  = $response->json('match.available_slots');
        $this->assertEquals($availableBefore - 1, $availableAfter);
    }

    /** @test */
    public function test_joining_a_full_match_returns_409(): void
    {
        $creator = $this->actingAsUser();
        $joiner  = $this->actingAsUser();
        $match   = $this->createMatch($creator, ['max_slots' => 1, 'available_slots' => 0]);

        $this->actingAs($joiner)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders())
            ->assertStatus(409)
            ->assertJsonStructure(['message']);
    }

    /** @test */
    public function test_joining_twice_returns_409(): void
    {
        $creator = $this->actingAsUser();
        $joiner  = $this->actingAsUser();
        $match   = $this->createMatch($creator, ['max_slots' => 4]);

        $this->actingAs($joiner)->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders());
        $this->actingAs($joiner)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders())
            ->assertStatus(409);
    }

    // ─── Women-Only Restriction ────────────────────────────────────────────────

    /** @test */
    public function test_male_user_cannot_join_women_only_match(): void
    {
        $creator = $this->actingAsUser(['gender' => 'female']);
        $male    = $this->actingAsUser(['gender' => 'male']);
        $match   = $this->createMatch($creator, ['women_only' => true, 'max_slots' => 4]);

        $this->actingAs($male)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders())
            ->assertForbidden()
            ->assertJsonPath('error_code', 'FEMALE_ONLY_MATCH_RESTRICTION');
    }

    /** @test */
    public function test_female_user_can_join_women_only_match(): void
    {
        $creator = $this->actingAsUser(['gender' => 'female']);
        $female  = $this->actingAsUser(['gender' => 'female']);
        $match   = $this->createMatch($creator, ['women_only' => true, 'max_slots' => 4]);

        $this->actingAs($female)
            ->postJson("/api/matches/{$match->id}/join", [], $this->jsonHeaders())
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    // ─── Leave ─────────────────────────────────────────────────────────────────

    /** @test */
    public function test_participant_can_leave_a_match(): void
    {
        $creator = $this->actingAsUser();
        $joiner  = $this->actingAsUser();
        $match   = $this->createMatch($creator, ['max_slots' => 4]);
        $match->participants()->attach($joiner->id);
        $match->syncAvailableSlots();

        $this->actingAs($joiner)
            ->postJson("/api/matches/{$match->id}/leave", [], $this->jsonHeaders())
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('sport_match_user', [
            'sport_match_id' => $match->id,
            'user_id'        => $joiner->id,
        ]);
    }

    /** @test */
    public function test_creator_cannot_leave_their_own_match(): void
    {
        $creator = $this->actingAsUser();
        $match   = $this->createMatch($creator);

        $this->actingAs($creator)
            ->postJson("/api/matches/{$match->id}/leave", [], $this->jsonHeaders())
            ->assertForbidden()
            ->assertJsonStructure(['message']);
    }

    // ─── Store ─────────────────────────────────────────────────────────────────

    /** @test */
    public function test_authenticated_user_can_create_a_match(): void
    {
        $user = $this->actingAsUser();

        $payload = [
            'sport_type'      => 'Football',
            'title'           => 'Sunday Kickabout',
            'date_time'       => now()->addDay()->toDateTimeString(),
            'location'        => 'Central Park',
            'available_slots' => 5,
            'skill_level'     => 'Beginner',
            'women_only'      => false,
        ];

        $this->actingAs($user)
            ->postJson('/api/matches', $payload, $this->jsonHeaders())
            ->assertCreated()
            ->assertJsonStructure(['id', 'title', 'available_slots', 'max_slots', 'users']);

        $this->assertDatabaseHas('sport_matches', ['title' => 'Sunday Kickabout']);
    }

    /** @test */
    public function test_creating_a_match_with_invalid_sport_type_returns_422(): void
    {
        $user = $this->actingAsUser();

        $this->actingAs($user)
            ->postJson('/api/matches', [
                'sport_type'      => 'Chess',   // not in SPORT_TYPES
                'title'           => 'Bad Match',
                'date_time'       => now()->addDay()->toDateTimeString(),
                'location'        => 'Somewhere',
                'available_slots' => 3,
                'skill_level'     => 'Beginner',
            ], $this->jsonHeaders())
            ->assertUnprocessable()
            ->assertJsonStructure(['message', 'errors']);
    }

    /** @test */
    public function test_male_user_cannot_create_women_only_match(): void
    {
        $user = $this->actingAsUser(['gender' => 'male']);

        $this->actingAs($user)
            ->postJson('/api/matches', [
                'sport_type'      => 'Football',
                'title'           => 'Ladies Game',
                'date_time'       => now()->addDay()->toDateTimeString(),
                'location'        => 'Ground B',
                'available_slots' => 5,
                'skill_level'     => 'Intermediate',
                'women_only'      => true,
            ], $this->jsonHeaders())
            ->assertForbidden()
            ->assertJsonPath('error_code', 'FEMALE_ONLY_MATCH_RESTRICTION');
    }

    // ─── Delete ────────────────────────────────────────────────────────────────

    /** @test */
    public function test_creator_can_delete_their_match(): void
    {
        $creator = $this->actingAsUser();
        $match   = $this->createMatch($creator);

        $this->actingAs($creator)
            ->deleteJson("/api/matches/{$match->id}", [], $this->jsonHeaders())
            ->assertNoContent();

        $this->assertDatabaseMissing('sport_matches', ['id' => $match->id]);
    }

    /** @test */
    public function test_non_creator_cannot_delete_a_match(): void
    {
        $creator  = $this->actingAsUser();
        $attacker = $this->actingAsUser();
        $match    = $this->createMatch($creator);

        $this->actingAs($attacker)
            ->deleteJson("/api/matches/{$match->id}", [], $this->jsonHeaders())
            ->assertForbidden();
    }
}
