<?php

namespace Database\Factories;

use App\Models\SportsMatch;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SportsMatch>
 */
class SportsMatchFactory extends Factory
{
    protected $model = SportsMatch::class;

    private static array $sportTypes  = ['Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket'];
    private static array $skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

    public function definition(): array
    {
        $openSlots = fake()->numberBetween(1, 9);

        return [
            'creator_id'      => User::factory(),
            'sport_type'      => fake()->randomElement(self::$sportTypes),
            'title'           => fake()->sentence(3),
            'date_time'       => now()->addDays(fake()->numberBetween(1, 30)),
            'location'        => fake()->city(),
            'latitude'        => fake()->latitude(),
            'longitude'       => fake()->longitude(),
            'available_slots' => $openSlots,
            'max_slots'       => $openSlots + 1, // +1 for the creator
            'skill_level'     => fake()->randomElement(self::$skillLevels),
            'women_only'      => false,
        ];
    }

    /** Create a women-only match. */
    public function womenOnly(): static
    {
        return $this->state(['women_only' => true]);
    }

    /** Create a match that is already at full capacity. */
    public function full(): static
    {
        return $this->state(['available_slots' => 0, 'max_slots' => 1]);
    }
}
