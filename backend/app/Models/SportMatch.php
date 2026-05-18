<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SportMatch extends Model
{
    protected $fillable = [
        'sport_type',
        'title',
        'date_time',
        'location',
        'latitude',
        'longitude',
        'available_slots',
        'skill_level',
    ];

    public function users()
    {
        return $this->belongsToMany(User::class, 'sport_match_user');
    }
}
