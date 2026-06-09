<?php

namespace App\Services;

use App\Models\Activity;

class ActivityService
{
    public static function create(
        $userId,
        $type,
        $message,
        $meta = []
    ) {
        return Activity::create([
            'user_id' => $userId,
            'type' => $type,
            'message' => $message,
            'meta' => $meta,
        ]);
    }
}
