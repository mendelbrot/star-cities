import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/game/icon_widgets/target_icon.dart';
import 'package:star_cities/features/game/icon_widgets/battle_icon.dart';
import 'package:star_cities/features/game/widgets/game_board_base.dart';
import 'package:star_cities/features/game/widgets/event_widgets/bombard_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/battle_collision_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/city_captured_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/faction_eliminated_event_widget.dart';
import 'package:star_cities/features/game/widgets/event_widgets/game_over_event_widget.dart';

class GameReplayBoard extends ConsumerWidget {
  final models.Game game;
  final List<Piece> pieces; // Initial turn state (Turn N)
  final Set<math.Point<int>> visibleSquares;
  final List<GameEvent> events;
  final Map<int, List<Piece>> snapshots;

  const GameReplayBoard({
    super.key,
    required this.game,
    required this.pieces,
    required this.visibleSquares,
    required this.events,
    required this.snapshots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));
    final currentUser = ref.watch(currentUserProvider);
    final uiState = ref.watch(gameplayUiProvider);

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhere(
          (p) => p.player.userId == currentUser?.id,
          orElse: () => players.first,
        );
        final homeStar = currentPlayer.player.homeStar;
        final centerX = homeStar?['x'] ?? 4;
        final centerY = homeStar?['y'] ?? 4;

        final replayPieces = _getReplayPieces(uiState.currentReplayStep);

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            final cellSize = size / 9;

            final currentEvents = events.where((e) => e.replayStep == uiState.currentReplayStep).toList();

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GameBoardBase(
                      stars: List<Map<String, int>>.from(game.stars.map((s) => Map<String, int>.from(s))),
                      pieces: replayPieces,
                      visibleSquares: visibleSquares,
                      playerFaction: currentPlayer.player.faction,
                      centerX: centerX,
                      centerY: centerY,
                      cellSize: cellSize,
                      onSquareTap: (x, y) => _handleReplayTap(ref, x, y, currentEvents, replayPieces),
                      onPieceTap: (piece) => _handleReplayTap(ref, piece.x!, piece.y!, currentEvents, replayPieces),
                      overlays: [
                        if (uiState.currentReplayStep == 1)
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(size, size),
                              painter: ReplayArrowPainter(
                                events: currentEvents,
                                centerX: centerX,
                                centerY: centerY,
                                cellSize: cellSize,
                                visibleSquares: visibleSquares,
                              ),
                            ),
                          ),
                        if (uiState.currentReplayStep == 2)
                           ...currentEvents.whereType<BombardEvent>().map((e) {
                             final pos = GameBoardBase.getRelativePosition(e.coord.x, e.coord.y, centerX, centerY);
                             return Positioned(
                               left: pos.x * cellSize + cellSize * 0.1,
                               top: pos.y * cellSize + cellSize * 0.1,
                               width: cellSize * 0.8,
                               height: cellSize * 0.8,
                               child: IgnorePointer(
                                 child: Center(
                                   child: TargetIcon(
                                     size: cellSize * 0.6,
                                     color: Colors.white.withValues(alpha: 0.8),
                                   ),
                                 ),
                               ),
                             );
                           }),
                         if (uiState.currentReplayStep == 4)
                           ...currentEvents.whereType<BattleCollisionEvent>().map((e) {
                             final pos = GameBoardBase.getRelativePosition(e.coord.x, e.coord.y, centerX, centerY);
                             return Positioned(
                               left: pos.x * cellSize + cellSize * 0.1,
                               top: pos.y * cellSize + cellSize * 0.1,
                               width: cellSize * 0.8,
                               height: cellSize * 0.8,
                               child: IgnorePointer(
                                 child: Center(
                                   child: BattleIcon(size: cellSize * 0.7),
                                 ),
                               ),
                             );
                           }),
                      ],
                    ),
                  ),
                ),
                if (uiState.selectedEvent != null)
                  Positioned.fill(
                    child: Center(
                      child: _buildEventOverlay(uiState.selectedEvent!, () {
                        ref.read(gameplayUiProvider.notifier).selectEvent(null);
                      }),
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading players: $e')),
    );
  }

  List<Piece> _getReplayPieces(int currentStep) {
    // Return the snapshot provided by backend for this step
    // Fallback logic for steps that reuse previous state
    int step = currentStep;
    if (step == 7) step = 6; // Step 7 state is same as Step 6 (final turn state)

    return snapshots[step] ?? pieces;
  }

  void _handleReplayTap(WidgetRef ref, int x, int y, List<GameEvent> currentEvents, List<Piece> pieces) {
    final eventAtSquare = currentEvents.where((e) {
      if (e is BombardEvent) return e.coord.x == x && e.coord.y == y;
      if (e is BattleCollisionEvent) return e.coord.x == x && e.coord.y == y;
      if (e is CityCapturedEvent) {
        final city = pieces.firstWhere((p) => p.id == e.cityId, orElse: () => pieces.first);
        return city.x == x && city.y == y;
      }
      return false;
    }).firstOrNull;

    if (eventAtSquare != null) {
      ref.read(gameplayUiProvider.notifier).selectEvent(eventAtSquare);
    }
  }

  Widget _buildEventOverlay(GameEvent event, VoidCallback onDismiss) {
    if (event is BombardEvent) {
      return BombardEventWidget(event: event, onDismiss: onDismiss);
    }
    if (event is BattleCollisionEvent) {
      return BattleCollisionEventWidget(event: event, onDismiss: onDismiss);
    }
    if (event is CityCapturedEvent) {
      return CityCapturedEventWidget(event: event, onDismiss: onDismiss);
    }
    if (event is FactionEliminatedEvent) {
      return FactionEliminatedEventWidget(event: event, onDismiss: onDismiss);
    }
    if (event is GameOverEvent) {
      return GameOverEventWidget(event: event, onDismiss: onDismiss);
    }
    return Container();
  }
}

class ReplayArrowPainter extends CustomPainter {
  final List<GameEvent> events;
  final int centerX;
  final int centerY;
  final double cellSize;
  final Set<math.Point<int>> visibleSquares;

  ReplayArrowPainter({
    required this.events,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
    required this.visibleSquares,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var event in events) {
      if (event is MoveEvent) {
        final isFromVisible = visibleSquares.contains(event.from);
        final isToVisible = visibleSquares.contains(event.to);
        if (!isFromVisible && !isToVisible) continue;

        final paint = Paint()
          ..color = event.faction.color.withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final start = GameBoardBase.getDrawPos(event.from.x, event.from.y, centerX, centerY, cellSize);
        final end = GameBoardBase.getDrawPos(event.to.x, event.to.y, centerX, centerY, cellSize);
        _drawArrow(canvas, start, end, paint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 12.0; 
    canvas.drawLine(
      end,
      Offset(end.dx - arrowSize * math.cos(angle - math.pi / 6), end.dy - arrowSize * math.sin(angle - math.pi / 6)),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(end.dx - arrowSize * math.cos(angle + math.pi / 6), end.dy - arrowSize * math.sin(angle + math.pi / 6)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
