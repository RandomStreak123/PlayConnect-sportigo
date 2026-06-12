<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Activity extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'message',
        'meta',
    ];

    protected $casts = [
        'meta' => 'array',
    ];

    protected $appends = [
        'userName',
        'userAvatar',
        'sportType',
        'matchTitle',
        'action',
        'time',
        'likedByMe',
        'likes',
        'comments',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getUserNameAttribute()
    {
        return $this->user ? $this->user->name : 'Sportigo User';
    }

    public function getUserAvatarAttribute()
    {
        if (!$this->user) {
            return null;
        }
        return $this->user->profile_photo ? asset('storage/' . $this->user->profile_photo) : ($this->user->profile_picture ? asset('storage/' . $this->user->profile_picture) : null);
    }

    public function getSportTypeAttribute()
    {
        return $this->meta['sport_type'] ?? 'Football';
    }

    public function getMatchTitleAttribute()
    {
        return $this->meta['title'] ?? '';
    }

    public function getActionAttribute()
    {
        $map = [
            'match_joined' => 'joined the match',
            'match_created' => 'created a match',
            'match_left' => 'left the match',
        ];
        return $map[$this->type] ?? $this->type;
    }

    public function getTimeAttribute()
    {
        return $this->created_at ? $this->created_at->diffForHumans() : '';
    }

    public function getLikedByMeAttribute()
    {
        return false;
    }

    public function getLikesAttribute()
    {
        return 0;
    }

    public function getCommentsAttribute()
    {
        return 0;
    }
}
