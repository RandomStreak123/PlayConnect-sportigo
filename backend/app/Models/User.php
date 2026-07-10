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

    public function followers()
    {
        return $this->belongsToMany(User::class, 'follows', 'followed_id', 'follower_id')->withTimestamps();
    }

    public function following()
    {
        return $this->belongsToMany(User::class, 'follows', 'follower_id', 'followed_id')->withTimestamps();
    }

    public function getFollowersCountAttribute()
    {
        return \Illuminate\Support\Facades\Cache::remember("user_followers_count_{$this->id}", 3600, function () {
            return $this->followers()->count();
        });
    }

    public function getFollowingCountAttribute()
    {
        return \Illuminate\Support\Facades\Cache::remember("user_following_count_{$this->id}", 3600, function () {
            return $this->following()->count();
        });
    }

    public function getIsFollowedAttribute()
    {
        $currentUser = auth('sanctum')->user();
        if (!$currentUser) {
            return false;
        }
        return $this->followers()->where('follower_id', $currentUser->id)->exists();
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

    public function clearStatsCache(): void
    {
        \Illuminate\Support\Facades\Cache::forget("user_stats_{$this->id}");
    }

    public function getStatsAttribute()
    {
        $uid = $this->id;

        return \Illuminate\Support\Facades\Cache::remember("user_stats_{$uid}", 3600, function () use ($uid) {
            $joinedMatches = $this->relationLoaded('joinedMatches')
                ? $this->joinedMatches
                : $this->joinedMatches()->select('sport_matches.id', 'creator_id', 'date_time', 'sport_type', 'title', 'location')->get();

            $hostedMatches = $this->relationLoaded('hostedMatches')
                ? $this->hostedMatches
                : \App\Models\SportsMatch::select('id', 'creator_id', 'date_time', 'sport_type', 'title', 'location')->where('creator_id', $uid)->get();

            $allPlayedMatches = $hostedMatches->merge($joinedMatches)
                ->unique('id');

            // Get pivot results for this user in a single fast query to avoid loading participants N+1
            $resultsMap = \Illuminate\Support\Facades\DB::table('sport_match_user')
                ->where('user_id', $uid)
                ->pluck('result', 'sport_match_id')
                ->toArray();

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

                $result = $resultsMap[$match->id] ?? null;

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
                'averageRating' => (float) $averageRating,
                'totalGames' => (int) $totalGames
            ];
        });
    }

    protected static $dbColumns = null;

    protected static function getDbColumns()
    {
        if (self::$dbColumns === null) {
            try {
                self::$dbColumns = \Illuminate\Support\Facades\Schema::getColumnListing('users');
            } catch (\Exception $e) {
                self::$dbColumns = [];
            }
        }
        return self::$dbColumns;
    }

    // Mutators for writing using legacy field names
    public function setPhoneAttribute($value)
    {
        $columns = self::getDbColumns();
        if (in_array('phone_number', $columns)) {
            $this->attributes['phone_number'] = $value;
        }
        if (in_array('phone', $columns)) {
            $this->attributes['phone'] = $value;
        }
    }

    public function setAvatarAttribute($value)
    {
        $columns = self::getDbColumns();
        if (in_array('avatar', $columns)) {
            $this->attributes['avatar'] = $value;
        }
        if (in_array('profile_picture', $columns)) {
            $this->attributes['profile_picture'] = $value;
        }
        if (in_array('profile_photo', $columns)) {
            $this->attributes['profile_photo'] = $value;
        }
    }

    public function setProfilePictureAttribute($value)
    {
        $columns = self::getDbColumns();
        if (in_array('avatar', $columns)) {
            $this->attributes['avatar'] = $value;
        }
        if (in_array('profile_picture', $columns)) {
            $this->attributes['profile_picture'] = $value;
        }
        if (in_array('profile_photo', $columns)) {
            $this->attributes['profile_photo'] = $value;
        }
    }

    public function setProfilePhotoAttribute($value)
    {
        $columns = self::getDbColumns();
        if (in_array('avatar', $columns)) {
            $this->attributes['avatar'] = $value;
        }
        if (in_array('profile_picture', $columns)) {
            $this->attributes['profile_picture'] = $value;
        }
        if (in_array('profile_photo', $columns)) {
            $this->attributes['profile_photo'] = $value;
        }
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
