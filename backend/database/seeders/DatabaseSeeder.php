<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $user = User::factory()->create([
            'name' => 'John Doe',
            'username' => 'johndoe',
            'phone_number' => '1234567890',
            'password' => 'password123',
        ]);

        $matches = [
            [
                'sport_type' => 'Football',
                'title' => 'Sunday Morning Football',
                'date_time' => now()->addDays(2)->setHour(10)->setMinute(0),
                'location' => 'Central Park Sports Ground',
                'latitude' => 40.785091,
                'longitude' => -73.968285,
                'available_slots' => 12,
                'skill_level' => 'Intermediate',
            ],
            [
                'sport_type' => 'Basketball',
                'title' => 'Hoops at Sunset',
                'date_time' => now()->addDays(1)->setHour(18)->setMinute(30),
                'location' => 'Venice Beach Courts',
                'latitude' => 33.9850,
                'longitude' => -118.4695,
                'available_slots' => 4,
                'skill_level' => 'Advanced',
            ],
            [
                'sport_type' => 'Tennis',
                'title' => 'Friendly Singles Match',
                'date_time' => now()->addDays(3)->setHour(14)->setMinute(0),
                'location' => 'Wimbledon Park',
                'latitude' => 51.4341,
                'longitude' => -0.2016,
                'available_slots' => 1,
                'skill_level' => 'Beginner',
            ],
        ];

        foreach ($matches as $matchData) {
            $match = \App\Models\SportMatch::create($matchData);
            $match->users()->attach($user->id);
        }
    }
}
