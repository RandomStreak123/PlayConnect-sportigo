<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Tournament;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Seed default users
        \App\Models\User::updateOrCreate(
            ['username' => 'ajith'],
            [
                'name' => 'Ajith',
                'email' => 'ajith@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
                'gender' => 'male',
                'avatar' => 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150',
                'phone' => '+91 98765 43210',
                'bio' => 'Passionate soccer player and competitive tournament host.',
                'role' => 'athlete'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'admin'],
            [
                'name' => 'Admin User',
                'email' => 'admin@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'primary_sport' => 'Tennis',
                'skill_tier' => 'Expert',
                'gender' => 'male',
                'avatar' => 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=150',
                'phone' => '+91 99999 88888',
                'bio' => 'System administrator and sports coordinator.',
                'role' => 'athlete'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'wembley'],
            [
                'name' => 'Wembley Arena',
                'email' => 'wembley@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'phone' => '+91 99999 77777',
                'bio' => 'World-class turf and sports facilities in Wembley.',
                'role' => 'venue',
                'avatar' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&q=80&w=150',
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
                'gender' => 'male'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'stadium'],
            [
                'name' => 'Stadium Turf',
                'email' => 'stadium@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'phone' => '+91 99999 66666',
                'bio' => 'Premium multi-sport stadium turf for local teams.',
                'role' => 'venue',
                'avatar' => 'https://images.unsplash.com/photo-1518063319789-7217e6706b04?auto=format&fit=crop&q=80&w=150',
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
                'gender' => 'male'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'camp_nou'],
            [
                'name' => 'Camp Nou Turf',
                'email' => 'camp_nou@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'phone' => '+91 99999 55555',
                'bio' => 'State of the art soccer pitches and coaching facilities.',
                'role' => 'venue',
                'avatar' => 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&q=80&w=150',
                'primary_sport' => 'Football',
                'skill_tier' => 'Advanced',
                'gender' => 'male'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'virat'],
            [
                'name' => 'Virat Kohli',
                'email' => 'virat@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'primary_sport' => 'Cricket',
                'skill_tier' => 'Professional',
                'gender' => 'male',
                'avatar' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=150',
                'phone' => '+91 98765 00001',
                'bio' => 'Professional cricketer. Love competitive matches.',
                'role' => 'athlete'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'sunil'],
            [
                'name' => 'Sunil Chhetri',
                'email' => 'sunil@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'primary_sport' => 'Football',
                'skill_tier' => 'Professional',
                'gender' => 'male',
                'avatar' => 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150',
                'phone' => '+91 98765 00002',
                'bio' => 'Striker. Always looking for a good football match.',
                'role' => 'athlete'
            ]
        );

        \App\Models\User::updateOrCreate(
            ['username' => 'saina'],
            [
                'name' => 'Saina Nehwal',
                'email' => 'saina@playconnect.com',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'primary_sport' => 'Badminton',
                'skill_tier' => 'Professional',
                'gender' => 'female',
                'avatar' => 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
                'phone' => '+91 98765 00003',
                'bio' => 'Badminton player. Let\'s play some singles or doubles!',
                'role' => 'athlete'
            ]
        );

        Tournament::create([
            'title' => 'Monsoon Futsal League 2026',
            'category' => 'Football',
            'description' => 'Annual 5-a-side futsal tournament with teams across Ernakulam. Professional referee supervision and certified match balls.',
            'start_date' => '2026-06-15 17:00',
            'fee' => '₹1,500 / Team',
            'max_teams' => 16,
            'registered_teams' => 12,
            'status' => 'open',
            'prize_pool' => '₹25,000 Cash Prize + Trophy',
            'format' => 'Single Elimination Futsal (5v5)',
            'organizer' => 'Kochi Arena Turf Officials',
            'banner_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Kochi Clay Court Tennis Open',
            'category' => 'Tennis',
            'description' => 'Singles knockout tournament at Regional Sports Centre. All skill tiers welcome. Hydration sponsor provided by Gatorade.',
            'start_date' => '2026-06-20 09:00',
            'fee' => '₹500 / Player',
            'max_teams' => 32,
            'registered_teams' => 18,
            'status' => 'open',
            'prize_pool' => 'Wilson Tennis Gear + Gold Medal',
            'format' => 'Knockout Bracket (Singles)',
            'organizer' => 'Regional Sports Centre (RSC)',
            'banner_url' => 'https://images.unsplash.com/photo-1560019175-ab10db47e7e9?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Corporate Cricket Bash',
            'category' => 'Cricket',
            'description' => 'T20 tournament for corporate clubs. 11-a-side matches with leather ball. Colored jerseys, refreshments, and lunch provided.',
            'start_date' => '2026-07-02 08:30',
            'fee' => '₹5,000 / Team',
            'max_teams' => 8,
            'registered_teams' => 5,
            'status' => 'open',
            'prize_pool' => '₹50,000 Cash Prize + Champions Cup',
            'format' => 'T20 Knockout (11-a-side)',
            'organizer' => 'Kerala Corporate Sports Board',
            'banner_url' => 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'PlayConnect Padel Masters',
            'category' => 'Padel',
            'description' => 'Doubles tournament. Come with a partner or request random matchmaking! Trophies and merchandise for top 3 teams.',
            'start_date' => '2026-06-28 16:00',
            'fee' => 'FREE',
            'max_teams' => 12,
            'registered_teams' => 11,
            'status' => 'open',
            'prize_pool' => 'Head Padel Rackets + Merch Hampers',
            'format' => 'Doubles (Direct Elimination)',
            'organizer' => 'PlayConnect Sports Network',
            'banner_url' => 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Kochi 3x3 Hoop Showdown',
            'category' => 'Basketball',
            'description' => 'Fast-paced half-court basketball tournament. DJ beats, street food trucks, and high-flying contest included.',
            'start_date' => '2026-07-10 15:00',
            'fee' => '₹800 / Team',
            'max_teams' => 16,
            'registered_teams' => 8,
            'status' => 'open',
            'prize_pool' => '₹15,000 Cash Prize + MVP Ring',
            'format' => '3v3 Half-Court Knockout',
            'organizer' => 'Kochi Ballers Association',
            'banner_url' => 'https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Highlands Amateur Golf Cup',
            'category' => 'Golf',
            'description' => '18-hole stroke play tournament on the pristine greens of Munnar Golf Club. Includes networking dinner.',
            'start_date' => '2026-08-05 07:00',
            'fee' => '₹2,500 / Golfer',
            'max_teams' => 40,
            'registered_teams' => 12,
            'status' => 'open',
            'prize_pool' => 'Premium Golf Bag + Silver Plate',
            'format' => 'Stroke Play (18 Holes)',
            'organizer' => 'Munnar Hills Golf Resort',
            'banner_url' => 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Monsoon Serenity Yoga Fest',
            'category' => 'Yoga',
            'description' => 'A morning of synchronized flow led by certified practitioners. Organic breakfast and wellness kits provided.',
            'start_date' => '2026-06-18 06:30',
            'fee' => 'FREE',
            'max_teams' => 100,
            'registered_teams' => 64,
            'status' => 'open',
            'prize_pool' => 'Premium Yoga Mat & Cork Block Set',
            'format' => 'Group Asana Session',
            'organizer' => 'SoulFlow Yoga Studio',
            'banner_url' => 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Ernakulam 10K Monsoon Run',
            'category' => 'Running',
            'description' => 'Annual scenic run along Marine Drive. Timing chips, finisher medals, and breakfast bag included for all runners.',
            'start_date' => '2026-07-19 05:45',
            'fee' => '₹400 / Runner',
            'max_teams' => 500,
            'registered_teams' => 312,
            'status' => 'open',
            'prize_pool' => 'Garmin Smartwatch (Top Finishers)',
            'format' => '10K Road Race',
            'organizer' => 'Kochi Runners Club',
            'banner_url' => 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Sunday Futsal Premier Cup',
            'category' => 'Football',
            'description' => 'Quick Sunday lightning knockout for local clubs at Decathlon Kalamassery.',
            'start_date' => '2026-06-25 14:00',
            'fee' => '₹1,000 / Team',
            'max_teams' => 8,
            'registered_teams' => 8,
            'status' => 'in_progress',
            'prize_pool' => 'Kipsta Match Balls + Winners Trophy',
            'format' => 'Single Elimination (5v5)',
            'organizer' => 'Decathlon Arena',
            'banner_url' => 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&q=80&w=600'
        ]);

        Tournament::create([
            'title' => 'Summer Doubles Tennis Smash',
            'category' => 'Tennis',
            'description' => 'Doubles tournament. Come with a partner or request random matchmaking! Trophies and merchandise for top teams.',
            'start_date' => '2026-07-15 16:00',
            'fee' => '₹600 / Team',
            'max_teams' => 16,
            'registered_teams' => 6,
            'status' => 'open',
            'prize_pool' => 'Babolat Racquet Bags + Medals',
            'format' => 'Doubles (Knockout)',
            'organizer' => 'Kochi Tennis Academy',
            'banner_url' => 'https://images.unsplash.com/photo-1595435066319-3544d6735be5?auto=format&fit=crop&q=80&w=600'
        ]);

        // Seed initial sync storage values for venues so they are not empty on first login
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venue_registry'],
            ['value' => json_encode(['wembley', 'stadium', 'camp_nou'])]
        );

        // Wembley Arena
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueName_wembley'],
            ['value' => 'Wembley Arena']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueLocation_wembley'],
            ['value' => 'London, UK']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venue_pitches_wembley'],
            ['value' => json_encode([
                [
                    'id' => 1,
                    'name' => 'Main Futsal Arena',
                    'type' => 'Football 5v5',
                    'nextSlots' => [
                        ['time' => '05:00 PM - 06:00 PM', 'status' => 'Vacant'],
                        ['time' => '06:00 PM - 07:00 PM', 'status' => 'Vacant'],
                        ['time' => '07:00 PM - 08:00 PM', 'status' => 'Vacant']
                    ]
                ],
                [
                    'id' => 2,
                    'name' => 'Wembley Grass Court',
                    'type' => 'Football 7v7',
                    'nextSlots' => [
                        ['time' => '06:00 PM - 07:30 PM', 'status' => 'Vacant'],
                        ['time' => '07:30 PM - 09:00 PM', 'status' => 'Vacant']
                    ]
                ]
            ])]
        );

        // Stadium Turf
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueName_stadium'],
            ['value' => 'Stadium Turf']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueLocation_stadium'],
            ['value' => 'Ernakulam, Kochi']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venue_pitches_stadium'],
            ['value' => json_encode([
                [
                    'id' => 1,
                    'name' => 'Stadium Pitch A',
                    'type' => 'Football 5v5',
                    'nextSlots' => [
                        ['time' => '04:00 PM - 05:00 PM', 'status' => 'Vacant'],
                        ['time' => '05:00 PM - 06:00 PM', 'status' => 'Vacant'],
                        ['time' => '06:00 PM - 07:00 PM', 'status' => 'Vacant']
                    ]
                ],
                [
                    'id' => 2,
                    'name' => 'Stadium Tennis Court',
                    'type' => 'Tennis Singles',
                    'nextSlots' => [
                        ['time' => '08:00 AM - 09:00 AM', 'status' => 'Vacant'],
                        ['time' => '09:00 AM - 10:00 AM', 'status' => 'Vacant']
                    ]
                ]
            ])]
        );

        // Camp Nou Turf
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueName_camp_nou'],
            ['value' => 'Camp Nou Turf']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venueLocation_camp_nou'],
            ['value' => 'Barcelona, Spain']
        );
        \App\Models\StorageSync::updateOrCreate(
            ['key' => 'venue_pitches_camp_nou'],
            ['value' => json_encode([
                [
                    'id' => 1,
                    'name' => 'Camp Nou Pitch',
                    'type' => 'Football 11v11',
                    'nextSlots' => [
                        ['time' => '05:00 PM - 07:00 PM', 'status' => 'Vacant'],
                        ['time' => '07:00 PM - 09:00 PM', 'status' => 'Vacant']
                    ]
                ]
            ])]
        );
    }
}
