# Turn Resolution Refactoring Proposal

This document outlines the architectural plan for refactoring the `resolve-turn` Supabase Edge Function. The goal is to move from a monolithic function to a modular, phase-based architecture that improves maintainability and testability.

## 1. Modular Phase Divisions

The turn resolution logic will be reorganized into five cohesive modules. Each module is responsible for a specific stage of the game's state transition.

### Phase 1: Preparation (`01_prepare.ts`)
- **Indexing**: Initializing the `TurnContext` with the current `state`, `stars`, and `players`.
- **Pre-processing**: Resetting per-turn flags (e.g., visibility, `wasJustPlaced`, `wasJustBombarded`).
- **Validation**: Filtering out invalid player actions based on the initial turn state.

### Phase 2: Intent Resolution (`02_intent.ts`)
- **Structural Actions**: Resolving `PLACE_ACT`, `TETHER_ACT`, and `ANCHOR_ACT`.
- **Dependency Handling**: Updating the context's indexes immediately as pieces are placed or anchored.
- **Event Generation**: Recording the outcome of these structural changes.

### Phase 3: Combat Resolution (`03_combat.ts`)
- **Bombardment**: Resolving range-based attacks, destruction checks, and applying the "Stun" effect (`wasJustBombarded`).
- **Movement & Battles**: Executing the iterative move application logic (Step 1-4) and resolving weighted-probability battles.
- **Cascading Losses**: Handling tether loss and piece removal during combat.

### Phase 4: Lifecycle & Economy (`04_lifecycle.ts`)
- **Faction Elimination**: Identifying and removing factions that have lost all Star Cities.
- **Acquisition**: Calculating and granting random new pieces to the tray for remaining players.

### Phase 5: Conclusion (`05_finalize.ts`)
- **Win Condition Check**: Determining if a player has met the star count victory requirements or if only one faction remains.
- **State Persistence**: Saving the final `turn_state` and `turn_events` to the database.
- **Game Transition**: Updating the `games` and `players` table statuses (e.g., transitioning to `FINISHED` or back to `PLANNING`).

---

## 2. Directory Structure

The function will be decomposed into the following file structure to promote separation of concerns:

```text
supabase/functions/resolve-turn/
├── index.ts                // Orchestration layer (Webhook entry point)
├── context.ts              // TurnContext class definition
├── utils.ts                // Shared logic (weightedRoll, distance, etc.)
└── phases/
    ├── 01-prepare.ts
    ├── 02-intent.ts
    ├── 03-combat.ts
    ├── 04-lifecycle.ts
    └── 05-finalize.ts
```

---

## 3. The `TurnContext` Pattern

To avoid passing numerous arguments between phases, a `TurnContext` object will act as the single source of truth for the duration of the resolution.

### Responsibilities:
- **State Management**: Holds the `workingState` (list of `Piece` objects).
- **Lookup Indexes**: Maintains high-performance Maps for `pieceMap`, `coordinateMap`, `tetherMap`, and `pieceContexts`.
- **Event Accumulation**: Provides a standard interface for phases to push new `GameEvent` records.
- **Metadata**: Stores `GameParameters`, `Star` coordinates, and `Player` status information.

### Interface Sketch:
```typescript
class TurnContext {
  pieces: Map<string, Piece>;
  coordinateMap: Map<string, string>;
  events: GameEvent[] = [];
  // ... helper methods for index updates
  
  updatePiecePosition(pieceId: string, to: Coordinate) {
    // Atomically updates piece and coordinateMap
  }
}
```

This pattern ensures that any change made by one phase (e.g., a Star City being captured in Phase 3) is immediately visible to subsequent operations (e.g., win condition checks in Phase 5).
