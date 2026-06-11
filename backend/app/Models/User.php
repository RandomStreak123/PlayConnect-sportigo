<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'username',
        'email',
        'password',
        'gender',
        'theme_preference',
        'phone_number',
        'hide_phone',
        'profile_picture',
        'profile_photo',
        'google_id',
        // Legacy/additional fields for tests
        'phone',
        'bio',
        'primary_sport',
        'skill_tier',
        'avatar',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $appends = [
        'profilePhotoUrl',
        'profilePicture',
        'stats',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'hide_phone' => 'boolean',
        ];
    }

    public function joinedMatches()
    {
        return $this->belongsToMany(SportsMatch::class, 'sport_match_user', 'user_id', 'sport_match_id')->withPivot('result')->withTimestamps();
    }

    public function tournaments()
    {
        return $this->belongsToMany(Tournament::class, 'tournament_user')->withPivot('team_name')->withTimestamps();
    }

    public function getProfilePhotoUrlAttribute()
    {
        $photo = $this->avatar;
        if ($photo) {
            if (str_starts_with($photo, 'http://') || str_starts_with($photo, 'https://')) {
                return $photo;
            }
            return asset('storage/' . $photo);
        }
        return null;
    }

    public function getProfilePictureAttribute()
    {
        $picture = $this->avatar;
        if ($picture) {
            if (str_starts_with($picture, 'http://') || str_starts_with($picture, 'https://')) {
                return $picture;
            }
            return asset('storage/' . $picture);
        }
        return null;
    }

    public function getStatsAttribute()
    {
        $uid = $this->id;

        $joinedMatches = $this->joinedMatches()->with('participants')->get();
        $hostedMatches = \App\Models\SportsMatch::with('participants')->where('creator_id', $uid)->get();
        
        $allPlayedMatches = $hostedMatches->merge($joinedMatches)
            ->unique('id')
            ->filter(function($m) {
                $time = $m->date_time ?? $m->date;
                return $time ? new \DateTime($time) < now()->addHours(24) : false;
            });

        $xp = 0;
        $wins = 0;
        $recordedMatchCount = 0;
        $createdCount = 0;

        foreach ($allPlayedMatches as $match) {
            $isCreator = ($match->creator_id ?? $match->user_id) == $uid;
            
            if ($isCreator) {
                $xp += 20;
                $createdCount++;
            } else {
                $xp += 5;
            }

            $xp += 15;

            $participant = $match->participants->where('id', $uid)->first();
            $result = $participant ? ($participant->pivot->result ?? null) : null;

            if ($result === 'win') {
                $xp += 25;
                $wins++;
                $recordedMatchCount++;
            } elseif ($result === 'loss' || $result === 'draw') {
                $recordedMatchCount++;
            }
        }

        $totalRatingsGiven = \App\Models\PlayerRating::where('rater_id', $uid)->count();
        $xp += $totalRatingsGiven * 10;

        $nextLevelXp = 1000;
        $level = floor($xp / $nextLevelXp) + 1;
        $currentLevelXp = $xp % $nextLevelXp;
        $progressPct = $nextLevelXp > 0 ? round(($currentLevelXp / $nextLevelXp) * 100) : 0;

        $winRate = $recordedMatchCount > 0 ? round(($wins / $recordedMatchCount) * 100) : 0;

        $streak = 0;
        $sortedMatches = $allPlayedMatches->sortByDesc('date_time');
        foreach ($sortedMatches as $match) {
            $participant = $match->participants->where('id', $uid)->first();
            $result = $participant ? ($participant->pivot->result ?? null) : null;
            if ($result === 'win') {
                $streak++;
            } elseif ($result === 'loss' || $result === 'draw') {
                break;
            }
        }

        $playStyle = 'All-Rounder';
        $totalGames = $allPlayedMatches->count();
        if ($totalGames > 0) {
            $createRatio = $createdCount / $totalGames;
            if ($createRatio >= 0.4) {
                $playStyle = 'Organizer';
            } elseif ($winRate >= 70) {
                $playStyle = 'Attacker';
            } elseif ($winRate < 50 && $recordedMatchCount >= 5) {
                $playStyle = 'Defender';
            }
        }

        $rankNum = max(1, 1000 - floor($xp / 5));

        return [
            'xp' => (int) $xp,
            'level' => (int) $level,
            'currentLevelXp' => (int) $currentLevelXp,
            'nextLevelXp' => (int) $nextLevelXp,
            'progressPct' => (int) $progressPct,
            'winRate' => (int) $winRate,
            'streak' => (int) $streak,
            'playStyle' => $playStyle,
            'globalRank' => "#{$rankNum} Kochi",
            'totalGames' => (int) $totalGames
        ];
    }

    // Mutators for writing using legacy field names
    public function setPhoneAttribute($value)
    {
        $this->attributes['phone_number'] = $value;
        $this->attributes['phone'] = $value;
    }

    public function setAvatarAttribute($value)
    {
        $this->attributes['avatar'] = $value;
        $this->attributes['profile_picture'] = $value;
        $this->attributes['profile_photo'] = $value;
    }

    public function setProfilePictureAttribute($value)
    {
        $this->attributes['avatar'] = $value;
        $this->attributes['profile_picture'] = $value;
        $this->attributes['profile_photo'] = $value;
    }

    public function setProfilePhotoAttribute($value)
    {
        $this->attributes['avatar'] = $value;
        $this->attributes['profile_picture'] = $value;
        $this->attributes['profile_photo'] = $value;
    }

    // Accessors for reading using legacy field names
    public function getPhoneAttribute()
    {
        return $this->attributes['phone_number'] ?? ($this->attributes['phone'] ?? null);
    }

    public function getAvatarAttribute()
    {
        return $this->attributes['profile_picture'] ?? ($this->attributes['avatar'] ?? null);
    }
}
