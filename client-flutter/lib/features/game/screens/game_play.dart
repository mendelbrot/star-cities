import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/features/game/widgets/game_board.dart';
import 'package:star_cities/shared/widgets/section_title.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/vision_provider.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/shared/widgets/responsive_game_header.dart';

import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/widgets/planning_panel.dart';
// import 'package:star_cities/features/game/widgets/replay_panel.dart';
import 'package:star_cities/features/game/widgets/game_over.dart';
import 'package:star_cities/features/game/widgets/player_rank_list_item.dart';
import 'package:collection/collection.dart';

import 'package:star_cities/features/game/widgets/event_widgets/bombard_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/battle_collision_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/city_captured_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/faction_eliminated_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/game_over_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/maneuver_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/advance_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_lost_tether_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_destroyed_event_widget.dart';

enum EventCategory {
  bombardments('Bombardments'),
  maneuvers('Maneuvers'),
  battles('Battles'),
  advances('Advances'),
  outcomes('Outcomes');

  final String label;
  const EventCategory(this.label);
}

final selectedEventTurnProvider = StateProvider.autoDispose.family<int, String>((ref, gameId) => 0);
final selectedEventCategoryProvider = StateProvider.autoDispose.family<EventCategory, String>((ref, gameId) => EventCategory.bombardments);

class GamePlay extends ConsumerWidget {
  final Game game;
  const GamePlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnStatesAsync = ref.watch(gameplayTurnStateProvider(game.id));
    final visionAsync = ref.watch(visionProvider(game.id));
    final eventsAsync = ref.watch(gameplayTurnEventsProvider(game.id));
    final playersWithProfilesAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));

    // Clear selection on turn or category change
    ref.listen(selectedEventTurnProvider(game.id), (_, _) {
      ref.read(gameplayUiProvider(game.id).notifier).selectEvent(null);
    });
    ref.listen(selectedEventCategoryProvider(game.id), (_, _) {
      ref.read(gameplayUiProvider(game.id).notifier).selectEvent(null);
    });
    ref.listen(gameProvider(game.id), (previous, next) {
      final prevGame = previous?.value;
      final nextGame = next.value;
      if (prevGame?.status != nextGame?.status || prevGame?.turnNumber != nextGame?.turnNumber) {
        ref.read(gameplayUiProvider(game.id).notifier).selectEvent(null);
      }
    });

    return turnStatesAsync.when(
      data: (turnStates) => visionAsync.when(
        data: (visions) => eventsAsync.when(
          data: (turnEventList) {
            final currentPieces = turnStates.isNotEmpty
                ? turnStates.first.pieces
                : <Piece>[];
            final currentVision = visions.isNotEmpty
                ? visions.first
                : <math.Point<int>>{};

            /*
            final previousPieces = turnStates.length > 1
                ? turnStates[1].pieces
                : <Piece>[];
            final previousVision = visions.length > 1
                ? visions[1]
                : <math.Point<int>>{};
            
            final events = turnEventList?.events ?? <GameEvent>[];
            final snapshots = turnEventList?.snapshots ?? <int, List<Piece>>{};
            */

            return TabBarView(
              children: [
                // Tab 1: Info / Scoreboard
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveGameHeader(
                            game: game,
                            chipsOnTop: true,
                            leading: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Game ID: ${game.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Turn: ${game.turnNumber}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const SectionTitle('scoreboard'),
                          const SizedBox(height: 16),
                          Expanded(
                            child: playersWithProfilesAsync.when(
                              data: (players) {
                                if (turnEventList == null || turnEventList.playerRanking.isEmpty) {
                                  // Fallback: Display all players sorted by faction
                                  final sortedPlayers = [...players]..sort((a, b) => a.player.faction.index.compareTo(b.player.faction.index));
                                  return ListView.builder(
                                    itemCount: sortedPlayers.length,
                                    itemBuilder: (context, index) => PlayerRankListItem(
                                      playerWithProfile: sortedPlayers[index],
                                    ),
                                  );
                                }

                                // Display ranked players
                                return ListView.builder(
                                  itemCount: turnEventList.playerRanking.length,
                                  itemBuilder: (context, index) {
                                    final ranking = turnEventList.playerRanking[index];
                                    final playerWithProfile = players.firstWhereOrNull(
                                      (p) => p.player.id == ranking.playerId,
                                    );
                                    
                                    if (playerWithProfile == null) return const SizedBox.shrink();
                                    
                                    return PlayerRankListItem(
                                      playerWithProfile: playerWithProfile,
                                      starCount: ranking.starCount,
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, s) => Center(child: Text('Error loading players: $e')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab 2: Events
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Selectors
                          Row(
                            children: [
                              // Turn Selector
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey('turn_${ref.watch(selectedEventTurnProvider(game.id))}'),
                                  decoration: const InputDecoration(
                                    labelText: 'Turn',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: ref.watch(selectedEventTurnProvider(game.id)) == 0 
                                      ? (game.turnNumber - 1).clamp(1, 999) 
                                      : ref.watch(selectedEventTurnProvider(game.id)),
                                  items: List.generate(
                                    game.turnNumber, 
                                    (i) => i + 1
                                  ).where((t) => t < game.turnNumber).map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('Turn $t'),
                                  )).toList().reversed.toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(selectedEventTurnProvider(game.id).notifier).state = val;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Category Selector
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<EventCategory>(
                                  key: ValueKey('category_${ref.watch(selectedEventCategoryProvider(game.id))}'),
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: ref.watch(selectedEventCategoryProvider(game.id)),
                                  items: EventCategory.values.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.label),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(selectedEventCategoryProvider(game.id).notifier).state = val;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Events List
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final selectedTurn = ref.watch(selectedEventTurnProvider(game.id)) == 0
                                    ? (game.turnNumber - 1).clamp(1, 999)
                                    : ref.watch(selectedEventTurnProvider(game.id));
                                
                                final historicalEventsAsync = ref.watch(historicalTurnEventsProvider((gameId: game.id, turnNumber: selectedTurn)));
                                final historicalStateAsync = ref.watch(historicalTurnStateProvider((gameId: game.id, turnNumber: selectedTurn)));
                                final historicalVisionAsync = ref.watch(historicalVisionProvider((gameId: game.id, turnNumber: selectedTurn)));

                                return historicalEventsAsync.when(
                                  data: (turnEvents) => historicalStateAsync.when(
                                    data: (turnState) => historicalVisionAsync.when(
                                      data: (vision) {
                                        if (turnEvents == null || turnState == null) {
                                          return const Center(child: Text('No historical data available for this turn.'));
                                        }
                                        
                                        final category = ref.watch(selectedEventCategoryProvider(game.id));
                                        final uiState = ref.watch(gameplayUiProvider(game.id));
                                        
                                        // Update replay step based on category
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          int targetStep = 2; // Default to Bombardment
                                          switch (category) {
                                            case EventCategory.bombardments: targetStep = 2; break;
                                            case EventCategory.maneuvers: targetStep = 3; break;
                                            case EventCategory.battles: targetStep = 4; break;
                                            case EventCategory.advances: targetStep = 5; break;
                                            case EventCategory.outcomes: targetStep = 6; break;
                                          }
                                          if (uiState.currentReplayStep != targetStep) {
                                            ref.read(gameplayUiProvider(game.id).notifier).setReplayStep(targetStep);
                                          }
                                        });

                                        final filteredEvents = turnEvents.events.where((e) {
                                          // Apply category filter
                                          bool inCategory = false;
                                          switch (category) {
                                            case EventCategory.bombardments: inCategory = e is BombardEvent; break;
                                            case EventCategory.maneuvers: inCategory = e is MoveEvent && e.replayStep == 3; break;
                                            case EventCategory.battles: inCategory = e is BattleCollisionEvent; break;
                                            case EventCategory.advances: inCategory = e is MoveEvent && e.replayStep == 5; break;
                                            case EventCategory.outcomes:
                                              inCategory = e is CityCapturedEvent || 
                                                     e is ShipDestroyedInBattleEvent || 
                                                     e is ShipDestroyedInBombardmentEvent || 
                                                     e is FactionEliminatedEvent || 
                                                     e is GameOverEvent ||
                                                     e is ShipLostTetherEvent;
                                              break;
                                          }
                                          if (!inCategory) return false;

                                          // Apply board selection filter for Bombardments and Battles
                                          if (uiState.selectedEvent != null && (category == EventCategory.bombardments || category == EventCategory.battles)) {
                                            return e == uiState.selectedEvent;
                                          }

                                          return true;
                                        }).toList();

                                        final showBoard = category != EventCategory.outcomes;

                                        final eventsListView = filteredEvents.isEmpty
                                            ? const Center(child: Text('No events in this category.'))
                                            : ListView.builder(
                                                padding: const EdgeInsets.only(bottom: 32),
                                                itemCount: filteredEvents.length,
                                                itemBuilder: (context, index) {
                                                  final event = filteredEvents[index];
                                                  final bool isFiltered = uiState.selectedEvent != null;
                                                  final onDismiss = isFiltered ? () => ref.read(gameplayUiProvider(game.id).notifier).selectEvent(null) : null;

                                                  if (event is BombardEvent) {
                                                    return BombardEventWidget(
                                                      event: event, 
                                                      onDismiss: onDismiss
                                                    );
                                                  } else if (event is BattleCollisionEvent) {
                                                    return BattleCollisionEventWidget(
                                                      event: event, 
                                                      onDismiss: onDismiss
                                                    );
                                                  } else if (event is CityCapturedEvent) {
                                                    return CityCapturedEventWidget(event: event);
                                                  } else if (event is FactionEliminatedEvent) {
                                                    return FactionEliminatedEventWidget(event: event);
                                                  } else if (event is GameOverEvent) {
                                                    return GameOverEventWidget(event: event);
                                                  } else if (event is MoveEvent && event.replayStep == 3) {
                                                    return ManeuverEventWidget(event: event);
                                                  } else if (event is MoveEvent && event.replayStep == 5) {
                                                    return AdvanceEventWidget(event: event);
                                                  } else if (event is ShipLostTetherEvent) {
                                                    return PieceLostTetherEventWidget(event: event);
                                                  } else if (event is ShipDestroyedInBattleEvent || event is ShipDestroyedInBombardmentEvent) {
                                                    return PieceDestroyedEventWidget(event: event);
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              );

                                        if (showBoard) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 16.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 300),
                                                  child: AspectRatio(
                                                    aspectRatio: 1,
                                                    child: GameBoard(
                                                      game: game,
                                                      pieces: turnState.pieces,
                                                      visibleSquares: vision,
                                                      events: turnEvents.events,
                                                      snapshots: turnEvents.snapshots,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(child: eventsListView),
                                              ],
                                            ),
                                          );
                                        }

                                        return eventsListView;
                                      },
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (e, s) => Center(child: Text('Error loading vision: $e')),
                                    ),
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (e, s) => Center(child: Text('Error loading state: $e')),
                                  ),
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, s) => Center(child: Text('Error loading events: $e')),
                                );
                              }
                            ),
                          ),
                          /* 
                          // Replay board hidden for now but preserved
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: GameBoard(
                                game: game,
                                pieces: previousPieces,
                                visibleSquares: previousVision,
                                events: events,
                                snapshots: snapshots,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ReplayPanel(gameId: game.id),
                          ),
                          */
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab 3: Planning / Game Over
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (game.status == GameStatus.finished) {
                      final winner = playersWithProfilesAsync.maybeWhen(
                        data: (players) => players.firstWhereOrNull((p) => p.player.isWinner),
                        orElse: () => null,
                      );
                      return GameOver(winner: winner);
                    }

                    final bool isWide = constraints.maxWidth > 800;

                    final boardWidget = GameBoard(
                      game: game,
                      pieces: currentPieces,
                      visibleSquares: currentVision,
                      isPlanning: true,
                    );

                    final panel = PlanningPanel(
                      game: game,
                      pieces: currentPieces,
                      flatten: !isWide,
                    );

                    Widget content;
                    if (isWide) {
                      content = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: boardWidget,
                            ),
                          ),
                          // Gap is provided by GameBoard's internal 16px padding
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                            child: SizedBox(
                              width: 370,
                              child: SingleChildScrollView(child: panel),
                            ),
                          ),
                        ],
                      );
                    } else {
                      content = Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: boardWidget,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: panel,
                          ),
                        ],
                      );
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: content,
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: GridLoadingIndicator(size: 60)),
          error: (e, s) => Center(child: Text('Error loading events: $e')),
        ),
        loading: () => const Center(child: GridLoadingIndicator(size: 60)),
        error: (e, s) => Center(child: Text('Error loading vision: $e')),
      ),
      loading: () => const Center(child: GridLoadingIndicator(size: 60)),
      error: (e, s) => Center(child: Text('Error loading turn state: $e')),
    );
  }
}
