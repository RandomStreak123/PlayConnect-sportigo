<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'is_read',
        'meta',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'meta' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getMessageAttribute($value)
    {
        if (empty($value)) {
            return $value;
        }
        $cleaned = preg_replace('/ at .*? scheduled for /i', ' scheduled for ', $value);
        return preg_replace('/(?<=") at .*?$/i', '', $cleaned);
    }
}
