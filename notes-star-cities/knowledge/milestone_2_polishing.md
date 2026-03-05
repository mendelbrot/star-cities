# Milestone 2 Polishing Strategy

This document outlines the refined plan for polishing the Star Cities frontend and backend integration, based on developer feedback from March 3rd, 2026.

## 1. System Architecture Refinements

### Auth & Profile (Metadata Strategy)
- **Source of Truth**: The `AppStateManager` will now check `userMetadata` in the JWT for the `username`. This eliminates database latency for the initial redirect.
- **Sync Logic**: Bi-directional triggers maintain sync between `auth.users` and `public.user_profiles`.
    - `auth.users` -> `public.user_profiles`: Updates the profile table when metadata changes (e.g., during onboarding).
    - `public.user_profiles` -> `auth.users`: Updates the JWT metadata when the profile is modified via the dashboard or other direct DB access.
- **Profile Page**: A single `/profile` route will handle both initial setup and subsequent edits. It will conditionally display an "INITIALIZE YOUR CALLSIGN" message if the username is missing.

### State Management (Riverpod)
- **Global Invalidation**: All data providers will watch an `authStateProvider`. Signing out will automatically dispose of all active streams and cached data.
- **Realtime Reliability**: `REPLICA IDENTITY FULL` is enabled on all game-related tables to ensure row deletions are captured by Supabase realtime streams.
- **Client-Side Joins**: To ensure reliable realtime updates, the Lobby and Game screens perform client-side joins of the `games` and `players` table streams rather than relying on database views.

## 2. Feature Improvements

### Lobby Organization (The 4-List View)
We will implement four distinct lists based on the user's relationship to the game and the turn status:

1.  **TAP Required (Turn Action Plan)**: Games the user has joined where `game.status == 'PLANNING'` and `player.is_ready == false`.
2.  **TAP Done**: Games the user has joined where `game.status == 'PLANNING'` and `player.is_ready == true`.
3.  **Waiting for Players**: Games the user has joined where `game.status == 'WAITING'`.
4.  **Open Games**: Games the user has **not** joined where `game.status == 'WAITING'`.

### Game Creation & UX
- **Streamlined Flow**: Implement a `LoadingOverlay` during game creation. The app will navigate to the game screen immediately upon receiving the new ID from the `insert` call, bypassing any list refresh delay.
- **Join/Leave Logic**:
    - Navigating to a game does **not** auto-join.
    - A "JOIN" button appears if the user isn't in the game.
    - A "LEAVE" button appears if they are.
    - Bot removal buttons are restricted to bot players only.
- **Clearer Status**: "THE GAME WILL START WHEN ALL PLAYER SPOTS ARE FILLED" message displayed in the waiting room.

## 3. Visual Identity & Styling
- **Theme Consistency**: All hard-coded colors (e.g., `Colors.red`) will be replaced with `Theme.of(context).colorScheme` or `Theme.of(context).primaryColor`.
- **Button Styling**: Fix the `FloatingActionButton` and `ElevatedButton` to strictly follow the sharp-edge, high-contrast theme.
- **Web Navigation**: Enable `usePathUrlStrategy()` to ensure the browser URL bar updates correctly during navigation.

## 4. Implementation Plan

1.  **Phase 1: Database & Logic**: Create bi-directional sync triggers and update `AppStateManager`.
2.  **Phase 2: Profile & Auth**: Realtime username availability (with debounce) and metadata-based setup.
3.  **Phase 3: Lobby Overhaul**: Implement the 4-list view with client-side joins and fix button styling.
4.  **Phase 5: Game Board Foundation**: Fix realtime update bugs and implement Join/Leave/Bot logic.
