<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        // 1. Fetch only social notifications from database (waving)
        $paginated = Notification::where('user_id', $request->user()->id)
            ->where('type', 'social')
            ->orderBy('id', 'desc')
            ->cursorPaginate(20);

        // 2. Fetch upcoming matches starting within the next 3 hours (Kolkata/Kochi timezone-aligned)
        $now = now('Asia/Kolkata');
        $threeHoursLater = now('Asia/Kolkata')->addHours(3);

        $joined = $request->user()->joinedMatches()
            ->whereBetween('date_time', [$now->toDateTimeString(), $threeHoursLater->toDateTimeString()])
            ->get();

        $hosted = \App\Models\SportsMatch::where('creator_id', $request->user()->id)
            ->whereBetween('date_time', [$now->toDateTimeString(), $threeHoursLater->toDateTimeString()])
            ->get();

        $upcomingMatches = $joined->merge($hosted)->unique('id');

        // 3. Synthesize upcoming match notifications
        $syntheticNotifications = $upcomingMatches->map(function ($match) {
            $formattedTime = \Carbon\Carbon::parse($match->date_time)->format('g:i A');
            $locationParts = explode(',', $match->location);
            $turfName = trim($locationParts[0]);
            return [
                'id' => 'upcoming-' . $match->id, // synthetic string ID
                'user_id' => $match->creator_id,
                'type' => 'upcoming_match',
                'title' => 'Upcoming Match Alert',
                'message' => "You have an upcoming match: {$match->sport_type} match \"{$match->title}\" at {$turfName} scheduled for {$formattedTime}.",
                'is_read' => false,
                'meta' => [
                    'match_id' => $match->id,
                    'sport_type' => $match->sport_type,
                    'title' => $match->title,
                    'location' => $match->location,
                    'date_time' => $match->date_time,
                ],
                'created_at' => now()->toIso8601String(),
                'updated_at' => now()->toIso8601String(),
            ];
        })->all();

        // 4. Merge synthetic notifications with paginated data
        $items = collect($syntheticNotifications)->merge($paginated->items());

        // Replace the items in the paginated collection
        $paginated->setCollection($items);

        return response()->json($paginated);
    }

    public function markAsRead(Request $request, $notificationId)
    {
        // Check if it is a synthetic notification ID (starts with 'upcoming-')
        if (is_string($notificationId) && str_starts_with($notificationId, 'upcoming-')) {
            return response()->json([
                'success' => true,
                'message' => 'Synthetic notification marked as read.'
            ]);
        }

        $notification = Notification::find($notificationId);
        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found.'
            ], 404);
        }

        if ($notification->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this notification.'
            ], 403);
        }

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'data' => $notification
        ]);
    }

    public function markAllAsRead(Request $request)
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read.'
        ]);
    }
}
