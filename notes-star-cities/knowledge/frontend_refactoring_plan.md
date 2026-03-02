# Frontend Refactoring Plan: Star Cities (REVISED)

This document outlines the architectural approach and implementation strategy for the new Star Cities Flutter frontend, incorporating feedback on Riverpod usage, styling, and feature requirements.

## 1. Core Principles
- **Data-Driven UI**: The UI should be a pure reflection of the backend `turn_states`, `turn_planned_actions`, and `turn_events`.
- **Surgical State Management**: Use Riverpod ONLY where it's the most pragmatic solution (e.g., complex game board logic). For simple data fetching or SDK-level features, use direct Supabase SDK calls (like `.stream()`).
- **Minimalist Aesthetic**: High-contrast (Black/White), sharp corners (0px radius), and JetBrains Mono font.
- **Realtime First**: Leverage Supabase Realtime for game transitions and player updates.

## 2. Feature & Module Breakdown

### A. Auth Feature
- **Status**: Already implemented.
- **Scope**: Sign-in, Sign-up, Sign-out using Supabase SDK.
- **Goal**: Add minimalist styling to the sign-in page.

### B. Profile Feature (NEW)
- **Status**: To be implemented.
- **Scope**: Manages the `user_profiles` table (`username`, `profile_icon`).
- **Goal**: Ensure every user has a username before accessing the game.
- **Logic**: Separate from Auth to maintain a clean distinction between Supabase `auth` schema and `public` schema.

### C. Lobby Feature
- **Status**: To be implemented.
- **Scope**:
    - "Your Active Turns": Filtered list of games for the current user.
    - "Waiting Games": Games available to join.
    - "Create Game": Form to set player count, adds current user to the game upon creation.

### D. Game Feature
- **Status**: To be implemented.
- **Screen**: `/game/:id` (UUID as path parameter).
- **Conditional Layout**:
    1. **Waiting UI**:
        - Player list with "Add Bot", "Kick Bot", "Join", "Leave" buttons.
        - Host-less permissions (any player can modify a waiting game).
    2. **Active UI (Tabs)**:
        - **Players Tab**: Scoreboard, star counts, and ready status.
        - **Replay Tab**: Visual step-by-step playback of `previousTurnEvents`.
        - **Planning Tab**:
            - 9x9 Torus Grid with "Portal" effect for wrap-around moves (arrows split across edges).
            - Local planning state with Undo/Reset/Submit.

## 3. Architecture & State Management

### Routing (GoRouter)
- **Realtime Profile Check**: The `GoRouter` `redirect` will check for a valid username in the `user_profiles` table.
- **Aggressive Redirect**: If no username is set, the user is locked into the `/profile` setup page.
- **Implementation**: A `ProfileNotifier` (ChangeNotifier) will listen to the Supabase profile stream and act as the `refreshListenable` for `GoRouter`.

### Riverpod Usage (Discernment)
- See `notes-star-cities/knowledge/frontend_riverpod_use.md` for the full list of providers and justifications.
- **Rule**: If a feature can be solved with a simple `StreamBuilder` or a `StatefulWidget`, it should be.

## 4. Visual Identity (Styling)
- **ThemeData**:
    - `ScaffoldBackgroundColor`: `#000000`
    - `PrimaryColor`: `#FFFFFF`
    - `FontFamily`: `JetBrains Mono`
    - `CardTheme/ButtonTheme`: `BorderRadius.zero`.
    - `InputBorder`: White 2px outlines.
- **Torus Board Rendering**:
    - 9x9 Grid lines.
    - **Portal Arrows**: When a move crosses an edge, draw a half-arrow exiting one side and another half-arrow entering from the opposite side.

## 5. Implementation Milestones

1. **Scaffold & Theme**: Set up JetBrains Mono, high-contrast theme, and clean up unused code from previous projects.
2. **Profile & Router**: Implement the `user_profiles` table sync and the aggressive `GoRouter` redirect.
3. **Lobby & Game Creation**: Simple list of games and creation form.
4. **Game Screen (Waiting UI)**: Realtime player list and open permissions for game setup.
5. **Game Board (Foundation)**: Render the 9x9 grid and static pieces from `turn_state`.
6. **Planning Logic (Riverpod justified)**: Implement the local action list, torus move validation, and "Portal" arrows.
7. **Replay Logic**: Sequential playback of turn events.
8. **Polish**: Finalizing UI interactions and battle summaries.
