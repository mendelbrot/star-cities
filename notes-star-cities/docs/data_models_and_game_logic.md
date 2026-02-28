# Star Cities Data Model


## 1. Tables

### Table: `user_profiles`
Publicly visible profile information for each user.
- **Fields**:
    - `id`: UUID (Primary Key, references `auth.users.id`)
    - `username`: TEXT (Unique)
    - `profile_icon`: TEXT (A string identifier for the selected icon)
    - `created_at`: TIMESTAMPTZ
    - `updated_at`: TIMESTAMPTZ

### Table: `games`
The primary record for a game instance.
- **Fields**:
    - `id`: UUID (Primary Key)
    - `status`: `game_status` (`WAITING | STARTING | PLANNING | RESOLVING | FINISHED`)
    - `turn_number`: Integer (Default 1)
    - `player_count`: Integer (Default 4)
    - `stars`: JSONB (`[{x, y}]` coordinates list)
    - `game_parameters`: JSONB (the game parameters JSON schema)
    - `winner`: UUID (Foreign Key to `players.id`, null if no winner)
    - `created_at`: TIMESTAMPTZ
    - `updated_at`: TIMESTAMPTZ

### Table: `players`
Links users or bots to games and assigns their faction.
- **Fields**:
    - `id`: UUID (Primary Key)
    - `game_id`: UUID (Foreign Key to `games`)
    - `user_id`: UUID (Foreign Key to auth users, null if `is_bot` is true)
    - `is_bot`: Boolean (Default FALSE)
    - `bot_name`: TEXT (Friendly name for the bot, null for human players)
    - `faction`: `faction` (`BLUE | RED | PURPLE | GREEN`)
    - `home_star`: JSONB (`{x, y}` coordinates)
    - `is_ready`: Boolean (Default FALSE)
    - `is_eliminated`: Boolean (Default FALSE)
    - `eliminated_on_turn`: Integer (Null if not eliminated)
    - `is_winner`: Boolean (Default FALSE)
- **Constraints**:
    - `player_identity`: Ensure either `user_id` is present OR `is_bot` is true.
    - `idx_unique_human_player_per_game`: A real user can only join a game once.
    - `UNIQUE(game_id, faction)`: Each faction is assigned once per game.

### Table: `turn_states`
Records the starting position of all pieces for a given turn.
- **Created by**: The Server (at the end of resolution for the *next* turn).
- **Fields**:
    - `id`: UUID (Primary Key)
    - `game_id` UUID
    - `turn_number` Integer
    - `state` (JSONB)
    - `created_at` TIMESTAMPTZ

### Table: `turn_planned_actions`
Records the intents submitted by players during the planning phase.
- **Created by**: The Client (one row per player, per turn).
- **Fields**:
    - `id`: UUID (Primary Key)
    - `game_id` UUID
    - `turn_number` Integer
    - `player_id` UUID
    - `actions` (JSONB)
    - `submitted_at` TIMESTAMPTZ

### Table: `turn_events`
Records the resolved outcomes that occurred during the transition between turns.
- **Created by**: The Server (once all players are ready or timer expires).
- **Fields**:
    - `id`: UUID (Primary Key)
    - `game_id` UUID
    - `turn_number` Integer
    - `events` (JSONB)
    - `created_at` TIMESTAMPTZ

---

## 2. JSON Schemas: 

## Game Parameters

```json
{
  "grid_size": 9,
  "star_count": 6,
  "star_count_to_win": 3,
  "max_ships_per_city": 5,
  "starting_ships": ["NEUTRINO", "NEUTRINO", "PARALLAX", "ECLIPSE"]
}
```

### Turn State
The `state` field in `turn_states` is a list of piece objects.
```json
{
  "id": "UUID",
  "faction": "BLUE | RED | PURPLE | GREEN",
  "type": "STAR_CITY | NEUTRINO | ECLIPSE | PARALLAX",
  "x": 0,         // 0-8, null if in tray
  "y": 0,         // 0-8, null if in tray
  "tether_id": "UUID", // ID of the Star City this ship is tethered to
  "is_anchored": false,
  "is_stunned": false,
  "is_visible": true,
  "is_in_tray": false
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
    "to": { "x": 2, "y": 3 },
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
    "type": "SHIP_LOST_TETHER",
    "faction": "RED",
    "piece_id": "UUID",
  },
  {
    "type": "BATTLE_COLLISION",
    "coord": { "x": 3, "y": 3 },
    "entering_participants": [
      { "piece_id": "UUID", "piece_type": "PARALLAX", "faction": "BLUE" },
      { "piece_id": "UUID", "piece_type": "ECLIPSE", "faction": "RED" }
    ],
    "defending_participant": null,
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
      {"faction": "RED", "strength": 11.0 },
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
    "did_someone_win": true,
  },
]
```


## 3. Turn Phases for turn N

1. Players review the turn N-1 state and events
2. Players see the state of turn N
3. Players submit their actions for turn N
4. The game server resolves the turn N state and events


## 4. Server-Side Event + State Resolution Logic


### Indexing State
Before processing actions, the server indexes the current turn's `state` (Turn N) for efficient lookup:
- **Piece Map**: `id -> Piece` (for quick retrieval of piece attributes).
- **Coordinate Map**: `(x, y) -> piece_id` (for collision checks and adjacency lookups).
- **Faction Placed PiecesMap**: `faction -> list of piece_ids` (for calculating vision or counting units - only the units placed on the map are included).
- **Faction Tray Map** `faction -> list of piece_ids` (for checking the pieces on the tray).
- **Tether Map**: `city_id -> list of ship_ids` (for range checks and tether loss propagation).
- **Piece Contexts Map**: `piece_id -> PieceTurnContext` (for tracking temporary turn state like `wasJustPlaced` or `wasJustDeanchored`).

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
    - There must not be a piece of the same faction moving to the same square.
    - The piece must not have `wasJustPlaced: true` in its context.
    - If the piece is a Star City, it must not be `is_anchored` AND must not have `wasJustDeanchored: true` in its context.
    - The target `to` must not be occupied by a ship that has `wasJustPlaced: true` in its context.
    - If the piece requires a tether (Eclipse, Parallax), the target `to` must be within range (2) of its current `tether_id`.

- **`BOMBARD_ACT`**:
    - The piece must be an `ECLIPSE`.
    - The `target_id` must exist and be an enemy piece.
    - The `target_id`'s position must be within range (2) of the attacker.

- **`TETHER_ACT`**:
    - The `ship_id` must be an ECLIPSE or PARALLAX.
    - The `city_id` must be an anchored friendly Star City.
    - The `city_id` must not have more than four ships tethered to it.
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
    - The `target` coordinate must not be the target of a `MOVE_ACT` by a friendly ship.



### Resolving State + Actions to Next State + Events

The server starts with a copy of the current game state, and gradually updates it to the next state while creating a list Events during this process. Let's call this copy of the state the "working state".

Actions are applied in a specific order, in phases to ensure consistent resolution. Each phase is based on a type of action and is run through for all in a way that ensures the result is independent of processing order. The phases are listed below.

1. Copy the state to the working state
    - set is_stunned=false for all ships
    - set is_visible=false for all NEUTRINO ships

2. Run through all PLACE_ACT, TETHER_ACT, and ANCHOR_ACT actions in the sequence they are given in each faction's actions list. 
    - validate against the working state and indexes, discard invalid actions
    - create the events add push them to the events list
    - update the working state
    - update the indexes

3. Resolve BOMBARD_ACT actions:
    - validate all bombardments against the working state and indexes, discard invalid actions
    - build an index (map) of target coordinate -> BOMBARD event, filling in the attackers and defender, then:

    - for each bombard event:
        - calculate is_destroyed with weighted probability 
        - push the events list
        - update is_stunned=true for the bombarded ship
        - if the ship is destroyed:
            - create and push a SHIP_DESTROYED_IN_BOMBARDMENT event
            - update the working state and indexes
            - put it through the handleTetherLoss function (this function will be explained in detail later, it removes tethers and untethered ships from the working state)

4. Resolve MOVE_ACT actions
    - overview: this phase will be done in steps:
        - in step 1 we will resolve all moves that can be made without conflict. this will require make a second list of moves that couldn't be resolved in this step, for the next step.
        - in step 2 we will resolve all battles
        - in step 3 we will destroy ships and transfer captured star cities
        - in step 4 we will again do double loop as in step 1 to make the remaining non-conflicting moves after battles have cleared some squares

    - Step 1
        - validate all moves against the working state and indexes, discard invalid actions
        - store the validated move actions in a way such that they can be marked as applied (true/false)
        - make a list of ships where it that ship the only ship moving to its target coordinate (the target coordinate may be currently occupied or not), (to do this, you may first build a map of coordinate -> list of ships moving there and then build the list from the items with just one ship)
        - loop through the following loop until it runs through with no moves made:
            - declare a list of ships that couldn't be moved in the last iteration of the below loop
            - declare a boolean flag stating if a ship was moved this loop, initially false
            - for each ship in the list
                - if the target coordinate is empty:
                    - push a new MOVE event 
                    - update the working state and indexes
                    - mark the move action for this ship as applied
                    - set the flag to true
                - otherwise
                    - push to the list of ships for the next loop
            - exit the upper loop if the flag is false
    
    - Step 2
        - from the un-applied moves, build a map of build a map of coordinate -> BATTLE_COLLISION events, filling the moving ships as entering participants
        - for each battle:
            - fill in all of the remaining fields
            - resolve the winner with a weighted probability
            - if the defending_participant is a star_city and its faction != the winning faction, set result=CAPTURE, otherwise set result=DESTROY
            - push the battle to the events list
    
    - Step 3
        - start a set list of destroyed ships
        - for each battle:
            - set is_visible=true for all NEUTRINO ships that are directly involved or are supporting ships
            - push all attacking ships not belonging to the winning faction to the set of destroyed ships
            - if result=DESTROY and the defending ship isn't of the winning faction, push it to the set of destroyed ships
        - for each destroyed ship:
            - create and push a SHIP_DESTROYED_IN_BATTLE event
            - update the working state and indexes
            - put it through the handleTetherLoss function
        - for each battle
            - if result=CAPTURE and the captured star city still exists
                - create and push a CITY_CAPTURED event
                - update the working state and indexes to transfer ownership
                - put the lost city through the handleTetherLoss function

    - Step 4
        - take the list of un-applied moves that was used at the beginning of step 2
        - filter out all moves of ships that no longer exist
        - perform the nested loop at the end of step one until no more moves can be applied

5. Check win condition and eliminated factions
    - **Identify Eliminated Factions**:
        - A faction is eliminated if it has no star cities on the board (star cities in the tray do not count).
        - For each newly eliminated faction:
            - Create and push a `FACTION_ELIMINATED` event.
            - Remove all of the factions pieces in the working state and indexes.
            - Mark the faction's is_eliminated and eliminated_on_turn fields.
    - **Check for Winner**:
        - Count the number of distinct stars each faction's Star Cities are currently anchored to.
        - A faction wins if it is anchored to 3 or more distinct stars AND has more stars than any other faction.
        - If only one non-eliminated faction remains, that faction wins.
        - If no winner is found:
            - If zero non-eliminated factions remain:
                - Create and push a `GAME_OVER` event with `did_someone_win: false`.
                - Update game status to `FINISHED`.
        - If a winner is found:
            - Create and push a `GAME_OVER` event with `winner: faction` and `did_someone_win: true`.
            - Update game status to `FINISHED`.
            - Update the player is_winner field to true.
            - Update the game winner field to the player id.

6. players acquire ships
  - for each player:
      - if their tray has less than 9 ships
          - based on the weighted probability create and push a PIECE_ACQUIRED event
          - update working state and indexes


7. save the list of events and the working state to the database, update the turn.


### The `handleTetherLoss` function
When a Star City is destroyed or captured, the ships tethered to it may be lost.

- **Input**: `lost_city_id`
- **Logic**:
    - if the input id is not a star city or doesn't exist, exit.
    - Identify all ships where `tether_id == lost_city_id`.
    - For each ship found:
        - Create and push a `SHIP_LOST_TETHER` event.
        - update the working state and indexes
