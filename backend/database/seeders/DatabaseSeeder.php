<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\SportsMatch;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        DB::table('sport_match_user')->truncate();
        DB::table('tournament_user')->truncate();
        DB::table('tournament_matches')->truncate();
        DB::table('tournaments')->truncate();
        DB::table('player_ratings')->truncate();
        DB::table('follows')->truncate();
        DB::table('activities')->truncate();
        DB::table('slots')->truncate();
        DB::table('notifications')->truncate();
        DB::table('personal_access_tokens')->truncate();
        DB::table('sport_matches')->truncate();
        DB::table('users')->truncate();
        Schema::enableForeignKeyConstraints();

        $usersData = [
            [
                'name' => 'Smriti',
                'username' => 'Smriti',
                'email' => 'eaglekgs@gmail.com',
                'password' => Hash::make('password'),
                'gender' => 'Female',
                'primary_sport' => 'Cricket',
                'skill_tier' => 'Intermediate',
            ],
            [
                'name' => 'Messi',
                'username' => 'Messi',
                'email' => 'messi@example.com',
                'password' => Hash::make('password'),
                'gender' => 'Male',
                'primary_sport' => 'Football',
                'skill_tier' => 'Professional',
            ],
            [
                'name' => 'Saina',
                'username' => 'Saina',
                'email' => 'sonugovindakk@gmail.com',
                'password' => Hash::make('password'),
                'gender' => 'Female',
                'primary_sport' => 'Badminton',
                'skill_tier' => 'Professional',
            ],
            [
                'name' => 'Eagle',
                'username' => 'Eagle',
                'email' => 'pkd20bcs149@gecskp.ac.in',
                'password' => Hash::make('password'),
                'gender' => 'Male',
                'primary_sport' => 'Football',
                'skill_tier' => 'Intermediate',
            ],
            [
                'name' => 'Bale',
                'username' => 'Bale',
                'email' => 'bale@example.com',
                'password' => Hash::make('password'),
                'gender' => 'Male',
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
            ],
            [
                'name' => 'Ajith',
                'username' => 'Ajith',
                'email' => 'ajith@example.com',
                'password' => Hash::make('password'),
                'gender' => 'Male',
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
            ]
        ];

        $users = [];
        foreach ($usersData as $data) {
            $users[] = User::create($data);
        }

        // Find users by username for easy reference
        $userMap = [];
        foreach ($users as $user) {
            $userMap[$user->username] = $user;
        }

        $matchesData = [
            [
                'creator_id' => $userMap['Smriti']->id,
                'sport_type' => 'Football',
                'title' => 'Spain vs Portugal',
                'date_time' => now()->addDays(2),
                'location' => 'Khel Academy Football Turf, Behind Police Station-Ktdc Road, Kazhakuttam, Thiruvananthapuram, Kerala, 695581',
                'available_slots' => 10,
                'max_slots' => 11,
                'skill_level' => 'Intermediate',
                'women_only' => false,
            ],
            [
                'creator_id' => $userMap['Saina']->id,
                'sport_type' => 'Badminton',
                'title' => 'Weekly Doubles',
                'date_time' => now()->addDays(3),
                'location' => 'One4 All Sports Hub, Souhrdha Nagar, Stadium Nettayakoanam, Near Green Field, Thiruvananthapuram, Kerala, 695581',
                'available_slots' => 3,
                'max_slots' => 4,
                'skill_level' => 'Professional',
                'women_only' => false,
            ],
            [
                'creator_id' => $userMap['Smriti']->id,
                'sport_type' => 'Football',
                'title' => 'Friendly Kickaround',
                'date_time' => now()->addDays(5),
                'location' => 'One4 All Sports Hub, Souhrdha Nagar, Stadium Nettayakoanam, Near Green Field, Thiruvananthapuram, Kerala, 695581',
                'available_slots' => 14,
                'max_slots' => 15,
                'skill_level' => 'Beginner',
                'women_only' => false,
            ],
            [
                'creator_id' => $userMap['Saina']->id,
                'sport_type' => 'Football',
                'title' => 'Women Evening Derby',
                'date_time' => now()->addDays(1),
                'location' => 'Godha Sports Indoor Cricket And Football Turf, Kizhakumbhagom Road, Kizhakkum Bhagam Residence Association, Pavithram, Thiruvananthapuram, Kerala, 695585',
                'available_slots' => 7,
                'max_slots' => 8,
                'skill_level' => 'Intermediate',
                'women_only' => true,
            ],
        ];

        $matches = [];
        foreach ($matchesData as $data) {
            $match = SportsMatch::create($data);
            $matches[] = $match;
            // The creator is automatically a participant
            $match->participants()->attach($data['creator_id']);
        }

        // Add some random other participants to matches to make them look active
        // E.g., Messi and Bale join Spain vs Portugal
        $userMap['Messi']->joinedMatches()->attach($matches[0]->id);
        $userMap['Bale']->joinedMatches()->attach($matches[0]->id);
        $matches[0]->syncAvailableSlots();

        // E.g., Ajith joins Weekly Doubles
        $userMap['Ajith']->joinedMatches()->attach($matches[1]->id);
        $matches[1]->syncAvailableSlots();

        // E.g., Eagle joins Friendly Kickaround
        $userMap['Eagle']->joinedMatches()->attach($matches[2]->id);
        $matches[2]->syncAvailableSlots();

        // Seed some activities
        $activitiesData = [
            [
                'user_id' => $userMap['Smriti']->id,
                'type' => 'match_created',
                'message' => 'Smriti created a Football match: "Spain vs Portugal"',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $userMap['Messi']->id,
                'type' => 'match_joined',
                'message' => 'Messi joined the Football match: "Spain vs Portugal"',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $userMap['Bale']->id,
                'type' => 'match_joined',
                'message' => 'Bale joined the Football match: "Spain vs Portugal"',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($activitiesData as $activity) {
            DB::table('activities')->insert($activity);
        }
    }
}
