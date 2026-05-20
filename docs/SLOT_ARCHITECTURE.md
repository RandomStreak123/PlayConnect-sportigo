# Sportigo — Match Slot Architecture

This document maps the generic **Flutter + Laravel slot update** pattern to Sportigo’s **match capacity** slots (not time-based booking slots).

## High-level flow

```text
┌──────────────────────┐
│     Flutter App      │
│  match_card / details│
└──────────┬───────────┘
           │  POST join / leave, GET matches
           ▼
┌──────────────────────┐
│    Laravel API       │
│  MatchController     │
│  MatchSlotService    │  ← business logic
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│     MySQL            │
│  sport_matches       │
│  sport_match_user    │
└──────────────────────┘
```

## Sportigo vs generic doc

| Generic doc | Sportigo |
|-------------|----------|
| `slot_model.dart` | `lib/data/models/match_model.dart` |
| `api_service.dart` | `lib/data/repositories/match_repository.dart` |
| `slot_provider.dart` | `lib/logic/blocs/matches/match_bloc.dart` |
| `PUT /slots/update` | `POST /matches/{id}/join`, `POST /matches/{id}/leave` |
| `SlotController` | `MatchController` |
| `SlotService` | `App\Services\MatchSlotService` |
| `slots` table | `sport_matches` + pivot `sport_match_user` |

## Slot fields (database)

| Column | Meaning |
|--------|---------|
| `max_slots` | Total players allowed (including creator) |
| `available_slots` | Open spots = `max_slots - joined_count` (synced on every change) |
| `joined_count` | Computed in API (`users` count) |
| `slots_left` | Computed in API = `max(0, max_slots - joined_count)` |

## Backend flow (join)

```text
Flutter: MatchJoined event
        │
        ▼
MatchRepository.joinMatch()
        │
        ▼
POST /api/matches/{id}/join
        │
        ▼
MatchController::join()
        │
        ▼
MatchSlotService::join()
   • lock row
   • reject if full
   • attach user
   • syncAvailableSlots()
        │
        ▼
JSON { success, match: { … slots_left, joined_count } }
        │
        ▼
MatchBloc upserts match in list → UI shows new slot count
```

## Frontend flow

```text
User taps Join
        │
        ▼
MatchCard → MatchBloc.add(MatchJoined)
        │
        ▼
MatchRepository → HTTP POST
        │
        ▼
MatchModel.fromJson(match)  // slots_left, joined_count, max_slots
        │
        ▼
Bloc replaces match in state.matches
        │
        ▼
Match card: "X slots left" updates immediately
```

## API endpoints

| Action | Method | Route |
|--------|--------|-------|
| List matches | GET | `/api/matches` |
| Join (consume slot) | POST | `/api/matches/{match}/join` |
| Leave (free slot) | POST | `/api/matches/{match}/leave` |
| Create match | POST | `/api/matches` |
| Creator edits capacity | PUT | `/api/matches/{match}` (`available_slots`) |

## Response shape (join / leave)

```json
{
  "success": true,
  "message": "Successfully joined",
  "match": {
    "id": 1,
    "max_slots": 10,
    "available_slots": 8,
    "joined_count": 2,
    "slots_left": 8,
    "users": [ … ]
  }
}
```

## Rules (single source of truth)

1. **Only** `MatchSlotService` + `SportMatch::syncAvailableSlots()` change capacity after join/leave/create.
2. Flutter displays `slots_left` / `max_slots - joined_count`, not stale `available_slots` alone.
3. On join failure (`Match is full`), bloc refetches matches so UI self-corrects.

## Real-time (optional later)

For live updates when another user joins:

- Laravel: `MatchSlotsUpdated` event after `syncAvailableSlots()`
- Broadcast via Pusher / Laravel Echo
- Flutter: listen and patch `MatchBloc` state

Not required for correct slot counts today; refetch-on-action is sufficient.

## Best practices (applied)

- **Transactional joins** with `lockForUpdate()` to avoid overbooking.
- **Service layer** keeps controllers thin.
- **Return updated match** from join/leave so Flutter does not guess slot counts.
- **Sync on read** (`index`, `mine`, `show`) repairs legacy bad rows.
