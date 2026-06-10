<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlayerRating extends Model
{
    use HasFactory;

    protected $table = 'player_ratings';

    protected $fillable = [
        'match_id',
        'rater_id',
        'rated_id',
        'rating',
    ];

    /**
     * The match this rating belongs to.
     */
    public function match()
    {
        return $this->belongsTo(SportsMatch::class, 'match_id');
    }

    /**
     * The user who gave the rating.
     */
    public function rater()
    {
        return $this->belongsTo(User::class, 'rater_id');
    }

    /**
     * The user who was rated.
     */
    public function rated()
    {
        return $this->belongsTo(User::class, 'rated_id');
    }
}
