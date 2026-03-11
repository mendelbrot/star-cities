# Robust Data Fetching Plan

## Overview
To address websocket connectivity issues and ensure data consistency, we are implementing a "REST -> Subscribe -> REST" pattern for core game data. This strategy ensures that the UI has data immediately, stays in sync via real-time updates, and handles any race conditions during the subscription initialization phase.

## Targeted Tables
The following tables will be moved to this robust fetching strategy:
1. `games`
2. `players` (Filtered by `game_id`)
3. `turn_states` (Filtered by `game_id`)
4. `turn_events` (Filtered by `game_id`)

## Pattern Logic
For each table, the `AsyncNotifier` will perform these steps in order:
1. **Initial REST Fetch**: Query Supabase via `select()` to populate the initial state.
2. **Realtime Subscription**: Initialize a `RealtimeChannel` and listen for `postgres_changes` (`*`).
3. **Secondary REST Sync**: Perform a second `select()` query to catch any missed updates that occurred between the first fetch and the successful subscription.

## Architecture

### 1. Reusable Base Class: `RobustSupabaseNotifier<T>`
We will create a generic base class to handle the boilerplate of fetching, subscribing, and merging data.

- **Type Parameters**:
  - `T`: The model type (e.g., `Game`, `Player`).
  - `ID`: The type of the unique identifier for the model.
- **Key Methods**:
  - `fetch()`: Performs the REST call.
  - `subscribe()`: Sets up the Supabase channel.
  - `onEvent()`: Handles incoming `INSERT`, `UPDATE`, `DELETE` events.
  - `merge()`: Updates the state with new data while preserving primary key uniqueness.

### 2. Implementation Files
- `lib/shared/providers/robust_stream_provider.dart`: Contains the `RobustSupabaseNotifier` base class.
- `lib/features/game/providers/game_providers.dart`: Update `gameProvider` and `playersProvider`.
- `lib/features/game/providers/gameplay_providers.dart`: Update `gameplayTurnStateProvider` and `gameplayTurnEventsProvider`.
- `lib/features/lobby/providers/lobby_providers.dart`: Update `gamesStreamProvider` and `playersStreamProvider`.

## Example Flow (Conceptual)
```dart
class GameNotifier extends RobustSupabaseNotifier<Game, String> {
  @override
  Future<void> build(String gameId) async {
    // 1. First REST Fetch
    state = AsyncValue.data(await fetch(gameId));
    
    // 2. Subscribe
    subscribe(gameId);
    
    // 3. Second REST Fetch (Sync)
    final syncData = await fetch(gameId);
    state = AsyncValue.data(merge(state.value, syncData));
  }
}
```

## Considerations
- **Filtering**: Most tables need `game_id` filtering. The base class must support passing filters to both REST and Realtime.
- **Race Conditions**: Incoming Realtime events during the second REST fetch should be applied. Since REST data is "the truth" at a point in time, we should ensure that the second fetch is the final authority for its timestamp, but subsequent Realtime events continue to update the state.
- **Switching Games**: When the `gameId` changes, the previous subscription must be properly disposed of to prevent memory leaks and incorrect updates.

## Next Steps
1. Create `robust_stream_provider.dart` with the base implementation.
2. Refactor `game_providers.dart` to use the new base class.
3. Refactor `gameplay_providers.dart` (merging REST fetching with Realtime).
4. Refactor `lobby_providers.dart` to improve the global game list reliability.
5. Verify with `flutter analyze`.
