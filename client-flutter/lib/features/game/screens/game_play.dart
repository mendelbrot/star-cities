import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/features/game/widgets/game_board.dart';
import 'package:star_cities/shared/widgets/section_title.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/vision_provider.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/shared/widgets/responsive_game_header.dart';

import 'package:star_cities/features/game/widgets/planning_panel.dart';
import 'package:star_cities/features/game/widgets/replay_panel.dart';

class GamePlay extends ConsumerWidget {
  final Game game;
  const GamePlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnStatesAsync = ref.watch(gameplayTurnStateProvider(game.id));
    final visionAsync = ref.watch(visionProvider(game.id));
    final eventsAsync = ref.watch(gameplayTurnEventsProvider(game.id));

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

            final previousPieces = turnStates.length > 1
                ? turnStates[1].pieces
                : <Piece>[];
            final previousVision = visions.length > 1
                ? visions[1]
                : <math.Point<int>>{};
            
            final events = turnEventList?.events ?? <GameEvent>[];

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
                          const Expanded(
                            child: Center(
                              child: Text('Scoreboard content will go here'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab 2: Replay
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: GameBoard(
                              game: game,
                              pieces: previousPieces,
                              visibleSquares: previousVision,
                              events: events,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: ReplayPanel(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab 3: Planning
                LayoutBuilder(
                  builder: (context, constraints) {
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
