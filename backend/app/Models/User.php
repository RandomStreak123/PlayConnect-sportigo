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
