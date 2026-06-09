<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'username',
        'email',
        'phone_number',
        'password',
        'profile_picture',
        'profile_photo',
        'gender',
        'hide_phone',
        'theme_preference',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $appends = [
        'profile_photo_url',
    ];

    public function getAvatarAttribute()
    {
        return $this->attributes['profile_picture'] ?? ($this->attributes['profile_photo'] ?? null);
    }

    public function getPhoneAttribute()
    {
        return $this->attributes['phone_number'] ?? null;
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
    }

    public function setAvatarAttribute($value)
    {
        $this->attributes['profile_picture'] = $value;
        $this->attributes['profile_photo'] = $value;
    }

    public function sportMatches()
    {
        return $this->belongsToMany(SportMatch::class, 'sport_match_user');
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'hide_phone' => 'boolean',
        ];
    }
}
