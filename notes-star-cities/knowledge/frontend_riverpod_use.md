# Star Cities - Riverpod Usage Guidelines

This document tracks the usage of Riverpod in the Star Cities project, providing technical rationale and documenting architectural decisions to ensure transparency and prevent over-engineering.

## Core Philosophy
1.  **Discernment First**: Use standard Flutter `StatefulWidget` or direct Supabase SDK features (like `.stream()`) if they are sufficient.
2.  **Justification Required**: Every Riverpod provider must solve a specific problem that is otherwise difficult or messy to solve (e.g., deeply nested state, complex cross-component dependencies).
3.  **No Auth/Router Overuse**: Do not use Riverpod for Authentication or Routing unless a standard Flutter pattern (like `ChangeNotifier` + `Listenable`) is demonstrably inferior.
4.  **Traceability**: All Riverpod usage must be documented here.

---

## Current Riverpod Implementations

### [Example Entry - Template]
*   **Problem**: [Describe the problem]
*   **Location**: [File path/Feature]
*   **Riverpod Objects**: [ProviderNames, Notifier types]
*   **Operation**: [Detailed technical explanation of how it works]
*   **Alternatives**: [Why wasn't a simpler approach used?]
*   **Justification**: [Summary of benefits]

---

## Proposed/Upcoming Riverpod Usage

### 1. Game Planning State
*   **Problem**: Managing the complex, ephemeral state of "Planned Actions" (moves, bombardments, etc.) on the 9x9 grid. Multiple components (the grid, the undo button, the action list sidebar) need to read and write to this state.
*   **Location**: `lib/features/game/presentation/providers/planning_provider.dart`
*   **Riverpod Objects**: `StateNotifierProvider` or `AsyncNotifierProvider`.
*   **Operation**: It will hold a list of `PlannedAction` objects. Tapping the board will trigger methods on the notifier to add/modify actions. The provider will also calculate the "valid moves" based on the current `turn_state`.
*   **Alternatives**: Passing a `ValueNotifier` down a deep tree of board/tile widgets, or using a massive `StatefulWidget` for the entire game board.
*   **Justification**: Riverpod's ability to "scope" providers to a specific game ID and its clean separation of logic from UI make it ideal for this high-interaction feature.

### 2. Game State Realtime Sync
*   **Problem**: Syncing the complex `turn_states`, `turn_events`, and `players` records in realtime across different tabs (Players, Replay, Planning).
*   **Location**: `lib/features/game/data/providers/game_sync_provider.dart`
*   **Riverpod Objects**: `StreamProvider`.
*   **Operation**: Wraps the Supabase `.stream()` or `.onReady()` listeners.
*   **Alternatives**: Using `StreamBuilder` directly in every widget that needs game data.
*   **Justification**: Centralizing the stream in a provider prevents redundant subscriptions and ensures that every part of the Game UI is looking at the exact same "source of truth".
