# Star Cities Data Model


## 1. Tables

### Table: `turn_states`
Records the starting position of all pieces for a given turn.
- **Created by**: The Server (at the end of resolution for the *next* turn).
- **Fields**: `game_id`, `turn_number`, `state` (JSONB), `created_at`.

### Table: `turn_planned_actions`
Records the intents submitted by players during the planning phase.
- **Created by**: The Client (one row per player, per turn).
- **Fields**: `game_id`, `turn_number`, `player_id`, `actions` (JSONB), `submitted_at`.

### Table: `turn_events`
Records the resolved outcomes that occurred during the transition between turns.
- **Created by**: The Server (once all players are ready or timer expires).
- **Fields**: `game_id`, `turn_number`, `events` (JSONB), `created_at`.

---

## 2. JSON Schemas: 

### Turn State
The `state` field in `turn_states` is a list of piece objects.
```json
{
  "id": "UUID",
  "faction": "BLUE | RED | YELLOW | GREEN",
  "type": "STAR_CITY | NEUTRINO | ECLIPSE | PARALLAX",
  "x": 0,         // 0-8, null if in tray
  "y": 0,         // 0-8, null if in tray
  "tether_id": "UUID", // ID of the Star City this ship is tethered to
  "is_anchored": false,
  "is_stunned": false,
  "is_visible": true 
}
```

### Turn Planned Actions
The `actions` field in `turn_planned_actions` is a list of action objects.

```json
[
    {
        "type": "MOVE",
        "piece_id": "UUID",
        "to": { "x": 2, "y": 3 }
    },
    {
        "type": "BOMBARD",
        "piece_id": "UUID",
        "target_id": "UUID"
    },
    {
        "type": "TETHER",
        "ship_id": "UUID",
        "city_id": "UUID"
    },
    {
        "type": "ANCHOR",
        "piece_id": "UUID",
        "is_anchored": true
    },
    {
        "type": "PLACE",
        "tray_piece_id": "UUID",
        "city_id": "UUID",
        "target": { "x": 1, "y": 2 }
    }
]
```

### Turn Events
The `events` field in `turn_events` is a list of event objects. The server generates these in a specific order for the client to "replay" (e.g., Bombardments first, then Moves, etc.).

```json
[
    {
        "type": "MOVE_SUCCESS",
        "piece_id": "UUID",
        "from": { "x": 1, "y": 3 },
        "to": { "x": 2, "y": 3 }
    },
    {
        "type": "TETHER",
        "ship_id": "UUID",
        "city_id": "UUID"
    },
    {
        "type": "ANCHOR",
        "piece_id": "UUID",
        "is_anchored": true
    },
    {
        "type": "PLACE",
        "tray_piece_id": "UUID",
        "city_id": "UUID",
        "target": { "x": 1, "y": 2 }
    },
    {
        "type": "BOMBARD_STUN",
        "coord": { "x": 4, "y": 4 },
        "attacking_pieces": [
          { "piece_id": "UUID", "piece_type": "ECLIPSE", "faction": "RED" }
          { "piece_id": "UUID", "piece_type": "ECLIPSE", "faction": "RED" }
        ],
        "target": { "piece_id": "UUID", "piece_type": "PARALLAX", "faction": "BLUE" },
        "attack_strength": 4,
        "target_strength": 6,
        "is_destroyed": false
    },
    {
      "type": "TETHER_LOST",
      "piece_id": "UUID",
    }
    {
        "type": "BATTLE_COLLISION",
        "coord": { "x": 3, "y": 3 },
        "participants": [
            { "piece_id": "UUID", "piece_type": "PARALLAX", "faction": "BLUE" },
            { "piece_id": "UUID", "piece_type": "ECLIPSE", "faction": "RED" }
        ],
        "supporting_participants": [
            { "piece_id": "UUID", "piece_type": "PARALLAX", "faction": "BLUE" },
            { "piece_id": "UUID", "piece_type": "STAR_CITY", "faction": "RED" },
            { "piece_id": "UUID", "piece_type": "NEUTRINO", "faction": "RED" }
        ],
        "calculated_strengths": [
            {"faction": "BLUE", "strength": 9.0 },
            {"faction": "RED", "strength": 9.0 },
        ],
        "winning_faction": "BLUE",
        "result": "CAPTURE | DESTROY"
    },
    {
        "type": "PIECE_ACQUIRED",
        "faction_id": "UUID",
        "piece_type": "ECLIPSE",
        "new_piece_id": "UUID"
}
]
```

---

## 3. Simultaneous Resolution Workflow

1.  **Turn Initialization**:
    - The server calculates the new `state` based on the previous state and events.
    - The server **Inserts** a new row into `turn_states` for `turn_number: N`.
2.  **Planning Phase**:
    - Players submit their actions.
    - Each player **Inserts** a row into `turn_planned_actions` for `turn_number: N`. 
    - (If a player updates their moves, they insert a new row; the server will use the latest one).
3.  **Resolution Phase**:
    - Server gathers the latest `turn_planned_actions` for all players in the game.
    - Server calculates the outcomes and **Inserts** a row into `turn_events`.
    - Server increments the game's `current_turn_number` and returns to Step 1.

---

## 4. Replay Logic
To replay Turn 5:
1. Fetch `turn_states` where `turn_number = 5`.
2. Fetch `turn_events` where `turn_number = 5`.
3. Render state -> Play event animations.
