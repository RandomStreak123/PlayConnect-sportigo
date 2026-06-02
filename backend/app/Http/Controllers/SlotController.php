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

    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => \App\Models\Slot::all()
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'slot_id' => 'required|integer',
            'new_time' => 'required|string',
        ]);

        $slot = \App\Models\Slot::findOrFail($validated['slot_id']);
        if ($slot->booked_by !== null && $slot->booked_by !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this slot.'
            ], 403);
        }

        $slot = $this->slotService->updateSlot($validated);

        return response()->json([
            'success' => true,
            'data' => $slot
        ]);
    }
}
