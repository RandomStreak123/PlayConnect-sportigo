<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StorageSync extends Model
{
    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'key',
        'value',
    ];
}
