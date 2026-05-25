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

    public function getProfilePhotoUrlAttribute()
    {
        $photo = $this->profile_photo ?? $this->profile_picture;
        if (!$photo) {
            return null;
        }
        if (filter_var($photo, FILTER_VALIDATE_URL)) {
            return $photo;
        }
        // If it starts with assets/, it is a frontend local asset path, return as is or return null
        if (str_starts_with($photo, 'assets/')) {
            return null; // The frontend will fallback to default avatar or use local assets directly
        }
        return asset('storage/' . $photo);
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
