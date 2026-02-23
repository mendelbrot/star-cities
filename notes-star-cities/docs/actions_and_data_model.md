# Star Cities Data Model


## 1. Tables

### Table: `turn_states`
Records the starting position of all pieces for a given turn.
- **Created by**: The Server (at the end of resolution for the *next* turn).
- **Fields**:
    - `game_id`
    - `turn_number`
    - `state` (JSONB)
    - `created_at`

### Table: `turn_planned_actions`
Records the intents submitted by players during the planning phase.
- **Created by**: The Client (one row per player, per turn).
- **Fields**:
    - `game_id`
    - `turn_number`
    - `player_id`
    - `actions` (JSONB)
    - `submitted_at`

### Table: `turn_events`
Records the resolved outcomes that occurred during the transition between turns.
- **Created by**: The Server (once all players are ready or timer expires).
- **Fields**:
    - `game_id`
    - `turn_number`
    - `events` (JSONB)
    - `created_at`

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
    "type": "MOVE_ACT",
    "piece_id": "UUID",
    "to": { "x": 2, "y": 3 }
  },
  {
    "type": "BOMBARD_ACT",
    "piece_id": "UUID",
    "target_id": "UUID"
  },
  {
    "type": "TETHER_ACT",
    "ship_id": "UUID",
    "city_id": "UUID"
  },
  {
    "type": "ANCHOR_ACT",
    "piece_id": "UUID",
    "is_anchored": true
  },
  {
    "type": "PLACE_ACT",
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
    "type": "MOVE",
    "faction": "RED",
    "piece_id": "UUID",
    "from": { "x": 1, "y": 3 },
    "to": { "x": 2, "y": 3 }
  },
  {
    "type": "TETHER",
    "faction": "RED",
    "ship_id": "UUID",
    "city_id": "UUID"
  },
  {
    "type": "ANCHOR",
    "faction": "RED",
    "piece_id": "UUID",
    "is_anchored": true
  },
  {
    "type": "PLACE",
    "faction": "RED",
    "tray_piece_id": "UUID",
    "city_id": "UUID",
    "target": { "x": 1, "y": 2 }
  },
  {
    "type": "BOMBARD",
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
    "faction": "RED",
    "piece_id": "UUID",
  },
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
    "supporting_bombardments": [
      { "piece_id": "UUID", "piece_type": "ECLIPSE", "faction": "RED" }
    ]
    "calculated_strengths": [
      {"faction": "BLUE", "strength": 9.0 },
      {"faction": "RED", "strength": 10.0 },
    ],
    "winning_faction": "BLUE",
    "result": "CAPTURE | DESTROY"
  },
  {
    "type": "PIECE_ACQUIRED",
    "faction": "RED",
    "piece_type": "ECLIPSE",
    "new_piece_id": "UUID"
  },
  {
    "type": "FACTION_ELIMINATED",
    "faction": "RED"
  },
  {
    "type": "GAME_OVER",
    "winner": "BLUE",
  },
]
```


## 3. Turn Phases

0. **Initial State**: 
  - The state of turn N in `turn_states` was calculated in phase 3 of turn N-1.
1. **Planned Actions (Players)**: 
  - Each player inserts a row into `turn_planned_actions` for `turn_number: N` containing their list of actions. 
2. **Event resolution (Server)**: 
  - Server gathers the latest `turn_planned_actions` for all players in the game.
  - Server calculates the outcomes and inserts a row into `turn_events`.
3. **State resolution (Server)**: 
  - Server increments the game's `current_turn_number`
  - The server calculates the `state` of turn N+1 based on the state and events of turn N.



## 4. Server-Side Event + State Resolution Logic


### Indexing State
TODO


### Validating Actions
TODO for each Action


### Event Order
1. anchor/de-anchor star cities
2. place ships
3. tether ships
4. bombard
5. move (for non-conflicting ie. non-battle moves)
6. battle
7. acquire ships


### Resolving Actions to Events
TODO


### Resolving State + Events to Next State
TODO