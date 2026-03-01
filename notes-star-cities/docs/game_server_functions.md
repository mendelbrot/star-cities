# Game Server Functions (Supabase Edge Functions)

This document outlines the high-level logic, database interactions, and triggers for the three core server-side functions.

---

## 1. `start-game`
**Goal:** Initialize the game board, generate the map, and set the initial state for Turn 1.

*   **Trigger Mechanism:** 
    1.  **Step 1 (SQL Trigger):** `trigger_check_game_full` on the `players` table. When the number of players matches `games.player_count`, it updates `games.status` from `'WAITING'` to `'STARTING'`.
    2.  **Step 2 (Supabase Webhook):** A Webhook configured in the Supabase Dashboard (`start_game`) listens for `UPDATE` events on the `games` table. When the status changes to `'STARTING'`, it sends a POST request to the `start-game` Edge Function.
*   **Database Reads:**
    *   `games`: Fetch `game_parameters` (grid size, star count, starting ships).
    *   `players`: Fetch the list of joined players to assign home stars.
*   **Logic:**
    1.  Generate random (but spaced) coordinates for the Stars.
    2.  Calculate "Home Star" positions for each player (equidistant if possible).
    3.  Generate initial `turn_states` (Turn 1):
        *   Place one `STAR_CITY` for each player near their Home Star.
        *   Populate each player's tray with their starting units (Neutrinos, etc.).
*   **Database Writes (Transaction):**
    1.  Insert row into `turn_states` for Turn 1.
    2.  Update `players`: Set `home_star` coordinates for each player.
    3.  Update `games`: Set `stars` JSONB and change `status` to `'PLANNING'`.


---

## 2. `resolve-turn`
**Goal:** Process the simultaneous moves of all players and transition the game from Turn N to Turn N+1.

*   **Trigger:**
    *   Database Webhook fires when a Postgres Function (`check_all_players_ready`) determines that all players for a `game_id` have `is_ready = true`.
*   **Architecture:**
    *   The function is modularized into five distinct phases for maintainability and clear resolution order.
    *   **Phase 1: Preparation (`01-prepare`)**: Fetches game data and initializes the `TurnContext` with lookup indexes.
    *   **Phase 2: Intent Resolution (`02-intent`)**: Processes `PLACE_ACT`, `TETHER_ACT`, and `ANCHOR_ACT` in the order they were submitted by the player.
    *   **Phase 3: Combat Resolution (`03-combat`)**: Resolves bombardment, validates movement, and executes iterative move application and battles.
    *   **Phase 4: Lifecycle & Economy (`04-lifecycle`)**: Handles faction elimination and random piece acquisition.
    *   **Phase 5: Conclusion (`05-finalize`)**: Checks win conditions, saves final state/events, and increments the turn.
*   **Logic Detail:**
    *   For a deep-dive into the resolution rules for each phase, see the **[Server-Side Event + State Resolution Logic](data_models_and_game_logic.md#resolving-state--actions-to-next-state--events-the-5-phase-model)** section of the Data Models documentation.
*   **Database Writes (Transaction):**
    1.  Insert `turn_events`: The sequence of events for Turn N (to be replayed by clients).
    2.  Insert `turn_states`: The resulting board state for Turn N+1.
    3.  Update `games`: Increment `turn_number`, update `status` (back to `'PLANNING'` or `'FINISHED'`), and set `winner` if applicable.
    4.  Update `players`: Reset `is_ready` to `false` for all non-eliminated players.

---

## 3. `player-bot`
**Goal:** Provide an automated participant to fill games or act as an opponent.

*   **Trigger:**
    *   Supabase Webhook configured to fire when `games.status` changes to `'PLANNING'`.
*   **Database Reads:**
    *   `players`: To identify which player IDs in the current game are bots and not eliminated.
*   **Logic (Current Scaffold):**
    1.  The function currently iterates through all active bots in the game.
    2.  It creates an empty list of `actions`.
    3.  Future implementation will include a **Decision Engine** to move toward stars, tether pieces, and bombard threats.
*   **Database Writes:**
    1.  Insert into `turn_planned_actions`: Save the bot's moves for the current turn.
    2.  Update `players`: Set `is_ready = true` for the bot.
