# Game Server Architecture (Supabase Edge Functions)

As an alternative to a dedicated Go server, Star Cities can utilize **Supabase Edge Functions** for turn resolution. This approach leverages a stateless, event-driven architecture that scales automatically and requires zero infrastructure management.

## 1. High-Level System Flow

The resolution follows a **Trigger-Process-Commit** pattern:

1.  **Trigger:** A Postgres Trigger on the `players` table detects when a player marks themselves as `is_ready`.
2.  **Orchestration:** A Postgres Function (`check_game_ready`) verifies if *all* players in the game are ready. If so, it invokes the `resolve-turn` Edge Function via a Database Webhook.
3.  **Compute (Deno/TypeScript):** The Edge Function fetches Turn N data, runs the 7-phase resolution logic, and generates the sequence of `Events`.
4.  **Commit (ACID Transaction):** The function performs a single atomic update to the database using a direct Postgres connection.

## 2. Triggering & Orchestration

To ensure efficiency and prevent "double-resolution" (race conditions), the logic is split between SQL and TypeScript:

*   **Postgres Trigger:** `AFTER UPDATE ON players FOR EACH ROW` calls `notify_game_ready()`.
*   **Postgres Function (`notify_game_ready`):**
    *   Checks if all players for the `game_id` have `is_ready = true`.
    *   Atomically updates `games.status` to `RESOLVING` to "lock" the game.
    *   Sends an HTTP POST request (Webhook) to the Edge Function URL.

## 3. Directory Structure (Supabase Project)

Edge Functions reside within the `supabase/functions/` directory:

```text
supabase/
├── functions/
│   ├── resolve-turn/
│   │   ├── index.ts        # Entry point (HTTP Handler)
│   │   ├── engine/         # The core game logic
│   │   │   ├── state.ts    # WorkingState class & Spatial Indexing
│   │   │   ├── torus.ts    # Torus math (9x9 grid wrap)
│   │   │   ├── phases.ts   # Implementation of the 7 logic phases
│   │   │   └── types.ts    # TypeScript interfaces for Pieces/Actions/Events
│   │   ├── db.ts           # Database connection & transaction logic
│   │   └── utils.ts        # Deterministic RNG (seeded by game/turn)
└── schemas/                # (Existing SQL schemas)
```

## 4. Core Logic Implementation

*   **WorkingState Class:** Implemented as a TypeScript class that manages the current turn's pieces. It maintains `Map<string, Piece>` for IDs and `Map<string, string>` for coordinate lookups.
*   **Spatial Indexing:** Coordinate keys are stored as strings (e.g., `"x,y"`) for $O(1)$ lookups.
*   **Database Transactions:** Since the `supabase-js` client (PostgREST) does not support multi-table ACID transactions, the function uses a direct Postgres driver (e.g., `postgres` JS library) to ensure that the new `turn_states`, `turn_events`, and `games` updates either all succeed or all fail.

## 5. Security & Constraints

*   **Authentication:** The Edge Function is protected by a `SERVICE_ROLE` key, ensuring only the Supabase system (via webhooks) can trigger it.
*   **Timeout:** Edge Functions typically have a 1-2 minute execution limit. For a 9x9 grid, resolution is expected to take milliseconds, well within this limit.
*   **Memory:** Deno's memory limit (usually 150MB-512MB) is more than sufficient for the Star Cities state.

## 6. Key Advantages vs. Go

*   **Integrated Workflow:** Logic lives in the same repository as the database schema.
*   **Zero Infrastructure:** No need to manage servers, Docker, or deployments on external providers like Fly.io or AWS.
*   **Cost:** Only pay for the milliseconds the function is actually running.
*   **TypeScript Synergy:** Sharing types between the Flutter frontend (via JSON/OpenAPI) and the Edge Function backend.
