<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$uid = 10;
$user = App\Models\User::find($uid);
echo "=== AJITH ACTIONS ORDER ===\n";

$actions = [];

// Joined matches
foreach ($user->joinedMatches as $m) {
    $actions[] = [
        'id' => $m->id,
        'title' => $m->title,
        'type' => 'Joined',
        'match_date' => $m->date_time,
        'action_date' => $m->pivot->created_at ? $m->pivot->created_at->toDateTimeString() : $m->created_at->toDateTimeString()
    ];
}

// Hosted matches
$hosted = App\Models\SportsMatch::where('creator_id', $uid)->get();
foreach ($hosted as $m) {
    // Check if not already in actions (avoid duplicates if any)
    $exists = false;
    foreach ($actions as $a) {
        if ($a['id'] == $m->id) {
            $exists = true;
            break;
        }
    }
    if (!$exists) {
        $actions[] = [
            'id' => $m->id,
            'title' => $m->title,
            'type' => 'Organized',
            'match_date' => $m->date_time,
            'action_date' => $m->created_at->toDateTimeString()
        ];
    }
}

// Sort by action_date descending
usort($actions, function ($a, $b) {
    return strcmp($b['action_date'], $a['action_date']);
});

foreach ($actions as $act) {
    echo "Action: {$act['type']} | Title: {$act['title']} | Match Date: {$act['match_date']} | Action Date: {$act['action_date']}\n";
}
