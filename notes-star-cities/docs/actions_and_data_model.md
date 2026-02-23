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
    "type": "CITY_CAPTURED",
    "city_id": "UUID",
    "from_faction": "RED",
    "to_faction": "BLUE"
  },
  {
    "type": "UNSUPPORTED_SHIP_LOST",
    "piece_id": "UUID", 
    "piece_type": "PARALLAX", 
    "faction": "BLUE"
  },
  {
    "type": "SHIP_DESTROYED_IN_BATTLE",
    "piece_id": "UUID", 
    "piece_type": "PARALLAX", 
    "faction": "BLUE"
  },
  {
    "type": "SHIP_DESTROYED_IN_BOMBARDMENT",
    "piece_id": "UUID", 
    "piece_type": "PARALLAX", 
    "faction": "BLUE"
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
Before processing actions, the server indexes the current turn's `state` (Turn N) for efficient lookup:
- **Piece Map**: `id -> Piece` (for quick retrieval of piece attributes).
- **Coordinate Map**: `(x, y) -> piece_id` (for collision checks and adjacency lookups).
- **Faction Map**: `faction -> list of piece_ids` (for calculating vision or counting units).
- **Tether Map**: `city_id -> list of ship_ids` (for range checks and tether loss propagation).

*Note: All coordinate lookups MUST account for the 9x9 torus wrap-around logic.*


### Validating Actions
Each action in `turn_planned_actions` must pass these checks. Invalid actions are discarded and do not generate events.

- **Global Checks**:
    - The `piece_id` must exist in the current state.
    - The piece must belong to the `player_id` who submitted the action.
    - The piece must not be `is_stunned`.
    - If the act is place, the the piece must be in the tray (have no x,y coordinates)
    - If the act is not place, then the piece must not be in the tray.

- **`MOVE_ACT`**:
    - Target `to` must be within the piece's `movement` range.
    - Target `to` must not be a "Star" (stars are permanent obstacles).
    - Target `to` must not be a friendly ship.
    - If the piece is a Star City, it must not be `is_anchored`.
    - If the piece requires a tether (Eclipse, Parallax), the target `to` must be within range (2) of its current `tether_id`.

- **`BOMBARD_ACT`**:
    - The piece must be an `ECLIPSE`.
    - The `target_id` must exist and be an enemy piece.
    - The `target_id`'s position must be within range (2) of the attacker.

- **`TETHER_ACT`**:
    - The `ship_id` must be an ECLIPSE or PARALLAX.
    - The `city_id` must be an anchored friendly Star City.
    - The `city_id` must not have more than five ships tethered to it.
    - The `ship_id`'s current position must be within range (2) of the `city_id`.

- **`ANCHOR_ACT`**:
    - The piece must be a `STAR_CITY`.
    - If `is_anchored` is `true`: The city must be adjacent (dist 1) to a Star.
    - If `is_anchored` is `false`: The city must have zero tethered ships.

- **`PLACE_ACT`**:
    - The `tray_piece_id` must exist in the player's tray (from the `turn_states`).
    - If the ship is ECLIPSE or PARALLAX, The `city_id` must be checked according to TETHER_ACT.
    - If the ship is `STAR_CITY` or `NEUTRINO`, the `city_id` must be null.
    - If the ship is ECLIPSE or PARALLAX, the `target` coordinate must be adjacent (dist 1) to the `city_id`.
    - If the ship is `STAR_CITY` or `NEUTRINO`, the `target` coordinate must be adjacent (dist 1) to any city of that player.
    - The `target` coordinate must not be a "Star".
    - The `target` coordinate must not be a ship.


### Event Order
1. anchor/de-anchor star cities
2. place ships
3. tether ships
4. bombard
5. move (for non-conflicting ie. non-battle moves)
6. battle
7. ship loss
8. acquire ships


### Resolving Actions to Events

Events are generated from validated actions in a specific order to ensure consistent resolution.

1. **ANCHOR/DE-ANCHOR**:
    - For each `ANCHOR_ACT`, generate an `ANCHOR` event. 
    - *If de-anchoring:* Update the city's `is_anchored` status immediately. If the city had any tethers, this should have been caught during validation.

2. **PLACE**:
    - For each `PLACE_ACT`, generate a `PLACE` event.
    - Note: Placement is always successful if the target square is empty at the start of the turn.

3. **TETHER**:
    - For each `TETHER_ACT`, generate a `TETHER` event.
    - Updates the `tether_id` of the ship for the rest of the resolution.

4. **BOMBARD**:
    - For each `BOMBARD_ACT`, generate a `BOMBARD` event.
    - Calculated strength is fixed at 2 for an Eclipse.
    - The target piece is flagged as `is_stunned` for the *next* turn.
    - If the target is a Star City and the `attack_strength >= target_strength`, the city is destroyed.

5. **MOVE (Non-Conflicting)**:
    - If a single piece moves to an empty square that no other piece is moving to, generate a `MOVE` event.
    - Update the piece's coordinates immediately.

6. **BATTLE (Conflicting Moves)**:
    - A `BATTLE_COLLISION` occurs when:
        - Multiple pieces from different factions attempt to move to the same square.
        - A piece moves to a square currently occupied by an enemy piece.
    - **Resolution**:
        - Calculate the `Winning Faction` using the weighted probability:
          `Weight = Unit Strength + (0.5 * Strength of Support Units)`
        - *Support Units:* Friendly units adjacent (dist 1) to the battle square.
    - **Outcome (Losing Faction)**:
        - All losing pieces involved in the collision are **destroyed**.
    - **Outcome (Winning Faction)**:
        - If the target square was **empty or occupied by enemy ships**: The winning piece occupies the target square.
        - If the target square was **occupied by an enemy Star City**: 
            - The Star City is **captured** (changes `faction`).
            - The winning piece **remains in its original starting square**.
            - All existing tethers to the city are lost (`TETHER_LOST` events for those ships).
    - Generate a `BATTLE_COLLISION` event with the winning faction and the resulting action (CAPTURE or DESTROY).

7. **ACQUIRE**:
    - For each player, calculate the random acquisition of a new piece based on the rules.
    - Generate a `PIECE_ACQUIRED` event for any new piece added to a player's tray.

8. **GAME STATE**:
    - Check if any faction's Star Cities are all captured/destroyed. Generate `FACTION_ELIMINATED`.
    - Check if a player has Star Cities anchored to 3 distinct stars. Generate `GAME_OVER`.


### Resolving State + Events to Next State

After all events for Turn N are resolved, the Server calculates Turn N+1's `state`:

1.  **Copy Turn N State**: Start with the `state` from `turn_states` for Turn N.
2.  **Apply Events**: Iteratively update the state based on the sequence of `turn_events`:
    - `MOVE`: Update `x`, `y`.
    - `ANCHOR`: Update `is_anchored`.
    - `TETHER`: Update `tether_id`.
    - `PLACE`: Create a new piece object with the given coordinates.
    - `BOMBARD`: If `is_destroyed` is true, remove the piece. If not, set `is_stunned` to true.
    - `BATTLE_COLLISION`: 
        - Remove all losing pieces (if DESTROY).
        - Update `faction` of Star City (if CAPTURE).
        - Winning piece stays in its *starting* square (if it was a collision with a city).
    - `TETHER_LOST`: The piece is **destroyed** (removed from state), unless it is a piece type that does not require a tether (e.g., Neutrino).
    - `PIECE_ACQUIRED`: Add a new piece to the state (with null `x`, `y` for the tray).
3.  **Post-Process State**:
    - **Tether Range Check**: For any piece requiring a tether (Eclipse, Parallax), if its `tether_id` is null, belongs to a different faction, or is out of range (dist > 2), the piece is destroyed (removed from state).
    - **Stun Reset**: For all pieces that were `is_stunned` at the start of Turn N, set `is_stunned` to false (unless they were just hit by a new `BOMBARD` event in step 2).
    - **Visibility**: Calculate `is_visible` for each piece for the start of Turn N+1 (Fog of War).
4.  **Save State**: Insert the final Turn N+1 state into the `turn_states` table.