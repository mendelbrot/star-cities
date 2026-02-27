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
*   **Database Reads:**
    *   `games`: Current turn number and status.
    *   `turn_states`: The starting state of the board for Turn N.
    *   `turn_planned_actions`: All actions submitted by players for Turn N.
*   **Logic:**
      // Phase 1: Indexing state
      // Phase 2: Resolve non-conflict actions (PLACE, TETHER, ANCHOR)
      // Phase 3: Resolve BOMBARD actions
      // Phase 4: Resolve MOVE actions and Battles
      // Phase 5: Check win condition and eliminated factions
      // Phase 6: Players acquire ships
      // Phase 7: Save next turn state and events
*   **Database Writes (Transaction):**
    1.  Insert `turn_events`: The sequence of events for Turn N (to be replayed by clients).
    2.  Insert `turn_states`: The resulting board state for Turn N+1.
    3.  Update `games`: Increment `turn_number`, update `status` (back to `'PLANNING'` or `'FINISHED'`), and set `winner` if applicable.
    4.  Update `players`: Reset `is_ready` to `false` for all players.

---

## 3. `player-bot`
**Goal:** Provide an automated participant to fill games or act as an opponent.

*   **Trigger:**
    *   Invoked via an Edge Function call (or Cron trigger) when a game enters the `'PLANNING'` phase and contains bot-controlled players.
*   **Database Reads:**
    *   `turn_states`: To see the current board and tray.
    *   `user_profiles` / `players`: To identify which player IDs are bots.
*   **Logic:**
    1.  **Vision Check:** Determine which enemy units are visible based on bot's piece vision ranges.
    2.  **Decision Engine:**
        *   Priority 1: Tether/Place pieces from tray.
        *   Priority 2: Move toward the nearest Star or enemy City.
        *   Priority 3: Bombard any visible threats.
    3.  **Action Generation:** Format decisions into the `turn_planned_actions` JSON schema.
*   **Database Writes:**
    1.  Upsert into `turn_planned_actions`: Save the bot's moves for the current turn.
    2.  Update `players`: Set `is_ready = true` for the bot.
