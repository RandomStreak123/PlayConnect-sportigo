<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SportsMatch extends Model
{
    use HasFactory;

    protected $table = 'sport_matches';

    protected $fillable = [
        'creator_id',
        'sport_type',
        'title',
        'date_time',
        'location',
        'status',
        'latitude',
        'longitude',
        'available_slots',
        'max_slots',
        'skill_level',
        'women_only',
        // Legacy fields for tests & compatibility
        'user_id',
        'category',
        'date',
        'price',
        'is_women_only',
    ];

    protected $casts = [
        'women_only' => 'boolean',
    ];

    protected $appends = [
        'creatorId',
        'sportType',
        'dateTime',
        'maxSlots',
        'womenOnly',
        'joinedCount',
        'organizer',
        'skillLevel',
        'category',
        'date',
        'slots_left',
        'slotsLeft',
        'users',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function participants()
    {
        return $this->belongsToMany(User::class, 'sport_match_user', 'sport_match_id', 'user_id')->withPivot('result')->withTimestamps();
    }

    public function getUsersAttribute()
    {
        return $this->participants;
    }

    public function getSlotsLeftAttribute(): int
    {
        $max = (int) ($this->max_slots ?? 0);
        return max(0, $max - $this->getJoinedCountAttribute());
    }

    public function syncAvailableSlots(bool $save = true): void
    {
        $joined = $this->relationLoaded('participants')
            ? $this->participants->count()
            : $this->participants()->count();

        $originalMax = $this->max_slots;
        $originalAvailable = $this->available_slots;

        if ($this->max_slots === null || $this->max_slots < $joined) {
            $this->max_slots = max($joined, (int) $this->available_slots + $joined);
        }

        $this->available_slots = max(0, $this->max_slots - $joined);

        if ($save && ($this->max_slots !== $originalMax || $this->available_slots !== $originalAvailable || $this->isDirty())) {
            $this->saveQuietly();
        }
    }

    // Accessors for frontend / api camelCase formatting
    public function getCreatorIdAttribute()
    {
        return $this->attributes['creator_id'] ?? ($this->attributes['user_id'] ?? null);
    }

    public function getSportTypeAttribute()
    {
        return $this->attributes['sport_type'] ?? ($this->attributes['category'] ?? null);
    }

    public function getDateTimeAttribute()
    {
        return $this->attributes['date_time'] ?? ($this->attributes['date'] ?? null);
    }

    public function getMaxSlotsAttribute()
    {
        return $this->attributes['max_slots'] ?? null;
    }

    public function getWomenOnlyAttribute()
    {
        return (bool) ($this->attributes['women_only'] ?? ($this->attributes['is_women_only'] ?? false));
    }

    public function getJoinedCountAttribute()
    {
        return $this->relationLoaded('participants')
            ? $this->participants->count()
            : $this->participants()->count();
    }

    public function getOrganizerAttribute()
    {
        return $this->user ? $this->user->name : 'Sportigo';
    }

    public function getSkillLevelAttribute()
    {
        return $this->attributes['skill_level'] ?? null;
    }

    // Backward-compatible accessors for legacy code & tests
    public function getCategoryAttribute()
    {
        return $this->attributes['sport_type'] ?? ($this->attributes['category'] ?? null);
    }

    public function getDateAttribute()
    {
        return $this->attributes['date_time'] ?? ($this->attributes['date'] ?? null);
    }

    // Mutators for writing using legacy field names
    public function setUserIdAttribute($value)
    {
        $this->attributes['creator_id'] = $value;
    }

    public function setCategoryAttribute($value)
    {
        $this->attributes['sport_type'] = $value;
    }

    public function setDateAttribute($value)
    {
        $this->attributes['date_time'] = $value;
    }

    public function setIsWomenOnlyAttribute($value)
    {
        $this->attributes['women_only'] = (bool) $value;
    }

    public function setPriceAttribute($value)
    {
        // Ignored as price is not a column in Sonu's sport_matches schema
    }
}
