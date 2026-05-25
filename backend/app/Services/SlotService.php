<?php

namespace App\Services;

use App\Models\Slot;

class SlotService
{
    public function updateSlot($data)
    {
        $slot = Slot::findOrFail($data['slot_id']);

        $slot->time = $data['new_time'];

        $slot->save();

        return $slot;
    }
}
