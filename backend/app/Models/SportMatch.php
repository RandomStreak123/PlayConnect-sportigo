<?php

namespace App\Models;

use Database\Factories\SportMatchFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SportMatch extends Model
{
    /** @use HasFactory<SportMatchFactory> */
    use HasFactory;

    protected $fillable = [
        'creator_id',
        'sport_type',
        'title',
        'date_time',
        'location',
        'latitude',
        'longitude',
        'available_slots',
        'max_slots',
        'skill_level',
        'women_only',
    ];

    protected $casts = [
        'women_only' => 'boolean',
        'available_slots' => 'integer',
        'max_slots' => 'integer',
        'creator_id' => 'integer',
    ];

    protected $appends = [
        'joined_count',
        'slots_left',
    ];

    public function getJoinedCountAttribute(): int
    {
        if ($this->relationLoaded('users')) {
            return $this->users->count();
        }

        return $this->users()->count();
    }

    public function getSlotsLeftAttribute(): int
    {
        $max = (int) ($this->max_slots ?? 0);

        return max(0, $max - $this->joined_count);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function users()
    {
        return $this->belongsToMany(User::class, 'sport_match_user');
    }

    public function syncAvailableSlots(): void
    {
        $joined = $this->relationLoaded('users')
            ? $this->users->count()
            : $this->users()->count();

        $originalMax = $this->max_slots;
        $originalAvailable = $this->available_slots;

        if ($this->max_slots === null || $this->max_slots < $joined) {
            $this->max_slots = max($joined, (int) $this->available_slots + $joined);
        }

        $this->available_slots = max(0, $this->max_slots - $joined);

        if ($this->max_slots !== $originalMax || $this->available_slots !== $originalAvailable || $this->isDirty()) {
            $this->saveQuietly();
        }
    }
}
