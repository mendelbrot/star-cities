# Milestone 2 Polishing Strategy

This document outlines the refined plan for polishing the Star Cities frontend and backend integration, based on developer feedback from March 3rd, 2026.

## 1. System Architecture Refinements

### Auth & Profile (Metadata Strategy)
- **Source of Truth**: The `AppStateManager` will now check `userMetadata` in the JWT for the `username`. This eliminates database latency for the initial redirect.
- **Sync Logic**: A database trigger on `auth.users` will sync `raw_user_meta_data` to the `public.user_profiles` table to maintain data integrity for other players to see.
- **Profile Page**: A single `/profile` route will handle both initial setup and subsequent edits. It will conditionally display an "INITIALIZE YOUR CALLSIGN" message if the metadata is missing.

### State Management (Riverpod)
- **Global Invalidation**: All data providers will watch an `authStateProvider`. Signing out will automatically dispose of all active streams and cached data.
- **Realtime Reliability**: Investigate `REPLICA IDENTITY FULL` on the `players` and `games` tables to ensure all row updates (including deletions) are captured by the Supabase realtime stream.

## 2. Feature Improvements

### Lobby Organization (The 4-List View)
We will implement four distinct lists based on the user's relationship to the game and the turn status:

1.  **TAP Required (Turn Action Plan)**: Games the user has joined where `game.status == 'PLANNING'` and `player.is_ready == false`.
2.  **TAP Done**: Games the user has joined where `game.status == 'PLANNING'` and `player.is_ready == true`.
3.  **Waiting for Players**: Games the user has joined where `game.status == 'WAITING'`.
4.  **Open Games**: Games the user has **not** joined where `game.status == 'WAITING'`.

### Database Optimization
I propose creating a **Postgres View** `v_user_game_status` to simplify these queries:
```sql
CREATE VIEW v_user_game_status AS
SELECT 
    g.id as game_id,
    g.status as game_status,
    g.turn_number,
    p.user_id,
    p.is_ready,
    p.faction
FROM games g
LEFT JOIN players p ON g.id = p.game_id;
```
*Note: This view allows us to find "Open Games" where `user_id` is NOT the current user and no player record exists for them.*

### Game Creation & UX
- **Streamlined Flow**: Implement a `LoadingOverlay` during game creation. The app will navigate to the game screen immediately upon receiving the new ID from the `insert` call, bypassing the Lobby's list refresh delay.
- **Join/Leave Logic**:
    - Navigating to a game does **not** auto-join.
    - A "JOIN" button appears if the user isn't in the game.
    - A "LEAVE" button appears if they are.
    - "DELETE" buttons are restricted to bot players only.

## 3. Visual Identity & Styling
- **Theme Consistency**: All hard-coded colors (e.g., `Colors.red`) will be replaced with `Theme.of(context).colorScheme` or `Theme.of(context).primaryColor`.
- **Button Styling**: Fix the `FloatingActionButton` and `ElevatedButton` to strictly follow the sharp-edge, high-contrast theme.
- **Web Navigation**: Enable `usePathUrlStrategy()` to ensure the browser URL bar updates correctly during navigation.

## 4. Implementation Plan

1.  **Phase 1: Database & Logic**: Create views, triggers, and update `AppStateManager`.
2.  **Phase 2: Profile & Auth**: Realtime username availability (with debounce) and metadata-based setup.
3.  **Phase 3: Lobby Overhaul**: Implement the 4-list view and fix button styling.
4.  **Phase 4: Game Board Foundation**: Fix realtime update bugs and implement Join/Leave/Bot logic.
