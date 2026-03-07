# Dev Log Analysis: March 6, 2026

## Summary of Changes & Observations

### Frontend Architecture & UI
- **Routing & Navigation:** 
    - Fixed routing issues by switching from `context.push` to `context.go` for primary navigation.
    - Reverted to the default hashtag URL strategy.
    - Identified the need for "Back to Lobby" links on Profile and Game Room pages.
    - Proposed a Game Setup screen (pushed via `context.push`) for configuring player counts (2-4).
- **Component Refactoring:**
    - `ShipIcon` identified as a candidate for simplification/statelessness.
    - Plan to decompose the Game Screen into specialized widgets (e.g., `GameBoard`).
    - Proposal to flatten feature folder structures: `models/`, `providers/`, `screens/`, `widgets/`.
- **Game Rules UI:** 
    - New `GameRules` widget requested, using Markdown and ship icons.
    - To be accessible via a `?rules` query parameter in the Lobby.
- **State Management:** 
    - Potential for a dedicated Game UI Riverpod provider to keep components stateless.
- **Aesthetics:** 
    - Ideas for a ship banner (row of 9) or a large Star City icon on the sign-in page.

### Backend & Data Models
- **Replay System:** 
    - Crucial addition: `replay_step` (INT) column needed in `turn_events`.
    - Steps: 1. Anchor/Tether, 2. Bombard, 3. Move (pre-battle), 4. Battle, 5. Move (post-battle).
    - `resolve-turn` function must populate this to enable step-by-step playback in the UI.
- **Bot Logic:** 
    - Improvement to bot naming: use unique names from a pool, defaulting to "Vaal".

### Technical Debt & Reliability
- **Cleanup:** Fixed `Faction` model placement (was inside `Player` model).
- **Websocket Stability:** Noted websocket errors on app resume. Considering a "REST for initial state + Stream for updates" pattern for better robustness.

## Analysis & Impact on Milestone 3

### 1. Foundation Strengthening (Pre-Milestone 3)
Before fully committing to Milestone 3 (Lobby & Game Creation), several "foundation" tasks from the log should be addressed:
- **Folder Flattening:** Standardizing the directory structure now will prevent friction as we add more widgets.
- **`replay_step` Implementation:** Since Milestone 3 involves the Game Screen (Waiting UI), ensuring the data model supports the eventual Replay Tab (Milestone 7) is proactive.
- **Routing Patterns:** Consistent use of `go` vs `push` and query parameters (`?rules`) needs to be established.

### 2. The "Replay Step" Logic
The addition of `replay_step` is the most significant logic change. It transforms the `turn_events` from a flat list into a sequenced script.
- **Backend Impact:** The `resolve-turn` function (Phase 3) needs to explicitly tag events with their sequence number.
- **Frontend Impact:** The `ReplayTab` will need to filter and "step" through these events, likely using a local state provider to track the current visible step.

### 3. Reliability Patterns
The websocket "warm-up" errors suggest we should formalize our data fetching pattern.
- **Proposed Pattern:** 
    1. Fetch current state via REST (standard Supabase query).
    2. Subscribe to the stream for delta updates.
    3. Use a Riverpod `AsyncValue` or similar to handle the transition/loading state.

### 4. UI/UX Refinement
The move toward stateless widgets and a dedicated Game UI provider aligns with the "Data-Driven UI" principle. Decomposing the Game Screen into smaller, focused widgets will make the implementation of the complex 9x9 Torus board (Milestone 5/6) much more manageable.

## Next Steps (Recommendations)
1. **Schema Update:** Add `replay_step` to `turn_events` in `02_tables.sql`.
2. **Refactor Infrastructure:** Implement the folder flattening and `ShipIcon` simplification.
3. **Routing & Setup:** Build the Game Setup screen and formalize the Lobby -> Game Room navigation flow.
