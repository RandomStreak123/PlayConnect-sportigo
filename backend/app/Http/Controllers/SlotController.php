<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\SlotService;

class SlotController extends Controller
{
    protected $slotService;

    public function __construct(SlotService $slotService)
    {
        $this->slotService = $slotService;
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'slot_id' => 'required|integer',
            'new_time' => 'required|string',
        ]);

        $slot = $this->slotService->updateSlot($validated);

        return response()->json([
            'success' => true,
            'data' => $slot
        ]);
    }
}
