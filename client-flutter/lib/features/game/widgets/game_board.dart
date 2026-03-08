import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';

class GameBoard extends ConsumerWidget {
  final models.Game game;
  final List<Piece> pieces;
  final Set<math.Point<int>> visibleSquares;

  const GameBoard({
    super.key,
    required this.game,
    required this.pieces,
    required this.visibleSquares,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, constraints.maxHeight);
          final cellSize = size / 9;

          return playersAsync.when(
            data: (players) {
              final currentPlayer = players.firstWhere(
                (p) => p.player.userId == currentUser?.id,
                orElse: () => players.first,
              );
              final homeStar = currentPlayer.player.homeStar;
              final centerX = homeStar?['x'] ?? 4;
              final centerY = homeStar?['y'] ?? 4;

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines
                      ...List.generate(10, (i) => Positioned(
                        left: i * cellSize,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                      )),
                      ...List.generate(10, (i) => Positioned(
                        top: i * cellSize,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                      )),
                      
                      // Stars (only if visible)
                      ...game.stars.where((star) => visibleSquares.contains(math.Point(star['x']!, star['y']!))).map((star) {
                        final pos = _getRelativePosition(star['x']!, star['y']!, centerX, centerY);
                        return Positioned(
                          left: pos.x * cellSize + cellSize * 0.25,
                          top: pos.y * cellSize + cellSize * 0.25,
                          width: cellSize * 0.5,
                          height: cellSize * 0.5,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),

                      // Pieces (only if visible)
                      ...pieces.where((piece) => piece.x != null && piece.y != null && (piece.isVisible || piece.faction == currentPlayer.player.faction) && visibleSquares.contains(math.Point(piece.x!, piece.y!))).map((piece) {
                        final pos = _getRelativePosition(piece.x!, piece.y!, centerX, centerY);
                        return Positioned(
                          left: pos.x * cellSize + cellSize * 0.1,
                          top: pos.y * cellSize + cellSize * 0.1,
                          width: cellSize * 0.8,
                          height: cellSize * 0.8,
                          child: ShipIcon(
                            type: piece.type,
                            faction: piece.faction,
                            size: cellSize * 0.8,
                            isAnchored: piece.isAnchored,
                          ),
                        );
                      }),

                      // Fog of War Overlay
                      ...List.generate(81, (i) {
                        final x = i % 9;
                        final y = i ~/ 9;
                        if (visibleSquares.contains(math.Point(x, y))) return const SizedBox.shrink();

                        final pos = _getRelativePosition(x, y, centerX, centerY);
                        return Positioned(
                          left: pos.x * cellSize,
                          top: pos.y * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: Container(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading players: $e')),
          );
        },
      ),
    );
  }

  // Torus wrapping relative position
  math.Point<int> _getRelativePosition(int x, int y, int centerX, int centerY) {
    int relX = (x - centerX + 4) % 9;
    int relY = (y - centerY + 4) % 9;
    if (relX < 0) relX += 9;
    if (relY < 0) relY += 9;
    return math.Point(relX, relY);
  }
}
