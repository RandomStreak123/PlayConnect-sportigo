<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class StorageSyncController extends Controller
{
    public function get(Request $request)
    {
        $keys = $request->input('keys', []);
        if (empty($keys) && $request->has('key')) {
            $keys = [$request->input('key')];
        }

        $query = \App\Models\StorageSync::where('user_id', auth()->id());

        if (empty($keys)) {
            return response()->json($query->get()->pluck('value', 'key'));
        }

        $items = $query->whereIn('key', $keys)->get()->pluck('value', 'key');
        return response()->json($items);
    }

    public function set(Request $request)
    {
        $request->validate([
            'key' => 'required|string',
            'value' => 'nullable|string',
        ]);

        $item = \App\Models\StorageSync::updateOrCreate(
            [
                'user_id' => auth()->id(),
                'key' => $request->key
            ],
            ['value' => $request->value]
        );

        return response()->json([
            'message' => 'Storage synchronized successfully',
            'key' => $item->key,
        ]);
    }
}
