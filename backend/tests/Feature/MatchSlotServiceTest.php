<?php

namespace Tests\Feature;

use App\Models\SportsMatch;
use App\Models\User;
use App\Services\MatchSlotService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Feature tests for MatchSlotService.
 *
 * Each test runs inside a real database transaction (RefreshDatabase),
 * so the SQLite in-memory DB is always clean between tests.
 */
class MatchSlotServiceTest extends TestCase
{
    use RefreshDatabase;

    private MatchSlotService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(MatchSlotService::class);
    }

    // ─── Helpers ───────────────────────────────────────────────────────────────

    private function makeUser(array $attrs = []): User
    {
        return User::factory()->create($attrs);
    }

    private function makeMatch(array $attrs = []): SportsMatch
    {
        $creator = $this->makeUser();
        $defaults = [
            'creator_id'      => $creator->id,
            'sport_type'      => 'Football',
            'title'           => 'Test Match',
            'date_time'       => now()->addDay(),
            'location'        => 'Test Ground',
            'available_slots' => 3,
            'max_slots'       => 4,
            'skill_level'     => 'Intermediate',
            'women_only'      => false,
        ];

        $match = SportsMatch::create(array_merge($defaults, $attrs));
        // Attach creator as participant
        $match->participants()->attach($creator->id);
        $match->syncAvailableSlots();

        return $match->fresh(['participants']);
    }

    // ─── Join Tests ────────────────────────────────────────────────────────────

    /** @test */
    public function test_a_user_can_successfully_join_a_match(): void
    {
        $match = $this->makeMatch(['max_slots' => 4]);
        $user  = $this->makeUser();

        $result = $this->service->join($match, $user);

        $this->assertArrayHasKey('match', $result);
        $this->assertArrayNotHasKey('error', $result);

        $this->assertTrue(
            $match->participants()->where('user_id', $user->id)->exists(),
            'User should be recorded as joined in the pivot table.'
        );
    }

    /** @test */
    public function test_joining_decrements_available_slots(): void
    {
        $match = $this->makeMatch(['max_slots' => 4, 'available_slots' => 3]);
        $user  = $this->makeUser();

        $slotsBefore = $match->available_slots;
        $this->service->join($match, $user);

        $match->refresh();
        $this->assertEquals($slotsBefore - 1, $match->available_slots);
    }

    /** @test */
    public function test_a_user_cannot_join_the_same_match_twice(): void
    {
        $match = $this->makeMatch(['max_slots' => 4]);
        $user  = $this->makeUser();

        $this->service->join($match, $user);
        $result = $this->service->join($match, $user);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals(409, $result['status']);
        $this->assertStringContainsStringIgnoringCase('already', $result['error']);
    }

    /** @test */
    public function test_a_user_cannot_join_a_full_match(): void
    {
        // Create a match already at capacity (1 creator = 1 slot, max = 1)
        $match = $this->makeMatch(['max_slots' => 1, 'available_slots' => 0]);
        $user  = $this->makeUser();

        $result = $this->service->join($match, $user);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals(409, $result['status']);
        $this->assertStringContainsStringIgnoringCase('full', $result['error']);
    }

    // ─── Leave Tests ───────────────────────────────────────────────────────────

    /** @test */
    public function test_a_participant_can_leave_a_match(): void
    {
        $match = $this->makeMatch(['max_slots' => 4]);
        $user  = $this->makeUser();
        $match->participants()->attach($user->id);
        $match->syncAvailableSlots();

        $result = $this->service->leave($match, $user);

        $this->assertArrayHasKey('match', $result);
        $this->assertFalse(
            $match->participants()->where('user_id', $user->id)->exists(),
            'User should be removed from the pivot table after leaving.'
        );
    }

    /** @test */
    public function test_leaving_increments_available_slots(): void
    {
        $match = $this->makeMatch(['max_slots' => 4]);
        $user  = $this->makeUser();
        $match->participants()->attach($user->id);
        $match->unsetRelation('participants');
        $match->syncAvailableSlots();

        $slotsBefore = $match->fresh()->available_slots;
        $this->service->leave($match, $user);

        $this->assertEquals($slotsBefore + 1, $match->fresh()->available_slots);
    }

    /** @test */
    public function test_a_non_participant_cannot_leave(): void
    {
        $match = $this->makeMatch();
        $user  = $this->makeUser();

        $result = $this->service->leave($match, $user);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals(404, $result['status']);
    }

    /** @test */
    public function test_the_creator_cannot_leave_their_own_match(): void
    {
        $creator = $this->makeUser();
        $match   = SportsMatch::create([
            'creator_id'      => $creator->id,
            'sport_type'      => 'Football',
            'title'           => 'Creator Match',
            'date_time'       => now()->addDay(),
            'location'        => 'Somewhere',
            'available_slots' => 3,
            'max_slots'       => 4,
            'skill_level'     => 'Beginner',
            'women_only'      => false,
        ]);
        $match->participants()->attach($creator->id);

        $result = $this->service->leave($match, $creator);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals(403, $result['status']);
        $this->assertStringContainsStringIgnoringCase('creator', $result['error']);
    }

    // ─── Slot Sync Tests ───────────────────────────────────────────────────────

    /** @test */
    public function test_sync_available_slots_does_not_write_when_values_are_unchanged(): void
    {
        $match = $this->makeMatch(['max_slots' => 4, 'available_slots' => 3]);

        // Capture the updated_at timestamp before the sync
        $updatedAtBefore = $match->updated_at;

        // Sleep 1 second so a write would change the timestamp
        sleep(1);
        $match->load('participants');
        $match->syncAvailableSlots();

        $this->assertEquals(
            $updatedAtBefore->toDateTimeString(),
            $match->fresh()->updated_at->toDateTimeString(),
            'syncAvailableSlots() should NOT write when slots are already correct.'
        );
    }

    /** @test */
    public function test_slots_left_accessor_matches_available_slots(): void
    {
        $match = $this->makeMatch(['max_slots' => 5]);
        $match->load('participants');

        $this->assertEquals(
            $match->slots_left,
            $match->available_slots,
            'The slots_left accessor must equal available_slots after a sync.'
        );
    }

    // ─── Create Match Tests ────────────────────────────────────────────────────

    /** @test */
    public function test_create_match_attaches_creator_as_first_participant(): void
    {
        $creator   = $this->makeUser();
        $validated = [
            'sport_type'      => 'Cricket',
            'title'           => 'New Match',
            'date_time'       => now()->addDay()->toDateTimeString(),
            'location'        => 'Ground A',
            'available_slots' => 5,
            'skill_level'     => 'Beginner',
        ];

        $match = $this->service->createMatch($validated, $creator, false);

        $this->assertTrue(
            $match->participants()->where('user_id', $creator->id)->exists(),
            'Creator must be automatically attached as a participant.'
        );
    }

    /** @test */
    public function test_create_match_sets_max_slots_correctly(): void
    {
        $creator   = $this->makeUser();
        $validated = [
            'sport_type'      => 'Tennis',
            'title'           => 'Tennis Game',
            'date_time'       => now()->addDay()->toDateTimeString(),
            'location'        => 'Court 1',
            'available_slots' => 3,
            'skill_level'     => 'Advanced',
        ];

        $match = $this->service->createMatch($validated, $creator, false);

        // max_slots = 3
        $this->assertEquals(3, $match->max_slots);
    }
}
