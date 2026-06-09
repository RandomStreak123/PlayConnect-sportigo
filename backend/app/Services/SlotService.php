<?php

namespace App\Services;

use App\Models\Slot;

class SlotService
{
    public function updateSlot(Slot $slot, array $data)
    {
        $slot->time = $data['new_time'];

        $slot->save();

        return $slot;
    }
}
