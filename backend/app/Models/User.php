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

    public function hostedMatches()
    {
        return $this->hasMany(SportsMatch::class, 'creator_id');
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
        $startTime = microtime(true);
        $uid = $this->id;

        $joinedMatches = $this->relationLoaded('joinedMatches')
            ? $this->joinedMatches
            : $this->joinedMatches()->with(['participants', 'user'])->get();

        if ($joinedMatches->isNotEmpty()) {
            if (!$joinedMatches->first()->relationLoaded('participants') || !$joinedMatches->first()->relationLoaded('user')) {
                $joinedMatches->load(['participants', 'user']);
            }
        }

        $hostedMatches = $this->relationLoaded('hostedMatches')
            ? $this->hostedMatches
            : \App\Models\SportsMatch::with(['participants', 'user'])->where('creator_id', $uid)->get();

        if ($hostedMatches->isNotEmpty()) {
            if (!$hostedMatches->first()->relationLoaded('participants') || !$hostedMatches->first()->relationLoaded('user')) {
                $hostedMatches->load(['participants', 'user']);
            }
        }
        
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
        $playedDates = $allPlayedMatches->map(function($m) {
            $time = $m->date_time ?? $m->date;
            return $time ? (new \DateTime($time))->format('Y-m-d') : null;
        })->filter(function($date) {
            return $date !== null && $date <= now()->format('Y-m-d');
        })->unique()->values()->all();


        if (count($playedDates) > 0) {
            rsort($playedDates);
            $nowDate = now()->format('Y-m-d');
            $yesterdayDate = now()->subDay()->format('Y-m-d');
            if ($playedDates[0] === $nowDate || $playedDates[0] === $yesterdayDate) {
                $streak = 1;
                for ($i = 0; $i < count($playedDates) - 1; $i++) {
                    $d1 = new \DateTime($playedDates[$i]);
                    $d2 = new \DateTime($playedDates[$i + 1]);
                    $diff = $d1->diff($d2)->days;
                    if ($diff === 1) {
                        $streak++;
                    } elseif ($diff > 1) {
                        break;
                    }
                }
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

        $avgRating = \App\Models\PlayerRating::where('rated_id', $uid)->avg('rating');
        $averageRating = $avgRating !== null ? round((float) $avgRating, 1) : 0.0;

        $stats = [
            'xp' => (int) $xp,
            'level' => (int) $level,
            'currentLevelXp' => (int) $currentLevelXp,
            'nextLevelXp' => (int) $nextLevelXp,
            'progressPct' => (int) $progressPct,
            'winRate' => (int) $winRate,
            'streak' => (int) $streak,
            'playStyle' => $playStyle,
            'globalRank' => "#{$rankNum} Kochi",
            'averageRating' => (float) $averageRating,
            'totalGames' => (int) $totalGames
        ];

        $duration = (microtime(true) - $startTime) * 1000;
        \Illuminate\Support\Facades\Log::info("User stats calculated in {$duration}ms for User ID {$uid}");

        return $stats;
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
