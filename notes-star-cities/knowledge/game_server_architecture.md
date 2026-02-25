# Game Server Architecture (Go)

The Star Cities game server functions as a centralized **Turn Resolution Engine**. Since clients interact directly with Supabase for turn planning, the Go server acts as an asynchronous worker that processes turns once all players have submitted their actions.

## 1. High-Level System Flow

The server operates in a **Read-Compute-Write** cycle:

1.  **Trigger:** The server is notified that a game is ready to resolve (e.g., all players in a game have `is_ready = true`).
2.  **Read (Hydration):** It fetches the current `games` record, the Turn N `turn_states`, and all Turn N `turn_planned_actions` from PostgreSQL.
3.  **Compute (Resolution Engine):** It initializes a "Working State" with spatial indexes, applies the 7 phases of logic sequentially (as defined in `data_models_and_game_logic.md`), resolves battles via weighted probabilities, and generates a sequence of `Events`.
4.  **Write (Commit):** It wraps the database updates in a single atomic transaction:
    *   Inserting the new `turn_states`.
    *   Inserting the new `turn_events`.
    *   Updating the `games` table (turn number, status, winner).
    *   Resetting player `is_ready` flags.

## 2. Triggering Mechanism

Two primary strategies for triggering turn resolution:

*   **Option A: Supabase Database Webhooks (Recommended):** The Go server exposes an HTTP endpoint (e.g., `POST /webhook/turn-ready`). A Supabase Postgres Trigger/Webhook fires whenever a `players` row is updated and `is_ready` becomes `true`. The Go server then verifies if *all* players in that `game_id` are ready before starting resolution.
*   **Option B: Polling Worker:** A Go ticker periodically queries the database for games where `status = 'WAITING'` and all players are ready.

## 3. Proposed Directory Structure

Following standard Go project layout conventions (DDD-lite):

```text
server-go/
├── cmd/
│   └── server/          # Entry point (main.go): wires up dependencies, starts HTTP server/worker
├── internal/
│   ├── api/             # HTTP handlers (e.g., for Supabase webhooks)
│   ├── db/              # Database access layer (queries, transactions)
│   ├── domain/          # Core data models (Game, Piece, Actions, Events JSON representations)
│   └── engine/          # The core game logic!
│       ├── state.go     # WorkingState struct and indexing (PieceMap, CoordinateMap, etc.)
│       ├── torus.go     # Math helpers for 9x9 torus wrap-around logic
│       ├── engine.go    # Orchestrates the 7 phases
│       ├── phase1_2.go  # Initialization, Place, Tether, Anchor
│       ├── phase3_4.go  # Bombardments, Movement, Battles, lossCascade
│       └── phase5_7.go  # Win conditions, Ship acquisition
└── pkg/                 # Shared utilities (logging, deterministic RNG)
```

## 4. Core Engine Design (`internal/engine`)

The Engine is designed to be entirely decoupled from the database for testing and replayability.

*   **`WorkingState` Struct:** Holds the `[]Piece` slice along with spatial maps (`CoordinateMap: map[string]uuid.UUID`, `TetherMap: map[uuid.UUID][]uuid.UUID`). Methods on this struct update the slice and maps atomically to maintain consistency.
*   **Torus Math:** A dedicated utility for calculating distances and adjacencies on a wrapping 9x9 grid.
*   **Deterministic Randomness:** To ensure replayability, the local random number generator (RNG) is seeded with a combination of `game_id` and `turn_number`. This ensures that re-running a resolution produces identical results (battle winners, ship acquisition).

## 5. Recommended Tech Stack

*   **Database Driver:** `jackc/pgx/v5` for high-performance PostgreSQL interaction.
*   **Database Queries:** `sqlc` for generating type-safe Go code from raw SQL queries.
*   **Web Framework:** `go-chi/chi` or standard library `net/http` for webhook endpoints.
