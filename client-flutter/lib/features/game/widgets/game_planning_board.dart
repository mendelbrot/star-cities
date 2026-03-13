import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_actions.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/utils/game_constants.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/game/icon_widgets/bombard_action_icon.dart';
import 'package:star_cities/features/game/widgets/game_board_base.dart';

class GamePlanningBoard extends ConsumerWidget {
  final models.Game game;
  final List<Piece> pieces;
  final Set<math.Point<int>> visibleSquares;

  const GamePlanningBoard({
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
    final uiState = ref.watch(gameplayUiProvider(game.id));
    final pendingActions = ref.watch(pendingActionsProvider(game.id));

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhereOrNull(
          (p) => p.player.userId == currentUser?.id,
        ) ?? players.first;
        
        final isPlanningMode = game.status == models.GameStatus.planning && !currentPlayer.player.isReady;

        final homeStar = currentPlayer.player.homeStar;
        final centerX = homeStar?['x'] ?? 4;
        final centerY = homeStar?['y'] ?? 4;

        final virtualPieces = _calculateVirtualPieces(pieces, pendingActions);
        final availableSquares = _calculateAvailableSquares(uiState, virtualPieces, currentPlayer.player.faction, pendingActions);

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            final cellSize = size / 9;

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GameBoardBase(
                  stars: List<Map<String, int>>.from(game.stars.map((s) => Map<String, int>.from(s))),
                  pieces: virtualPieces,
                  visibleSquares: visibleSquares,
                  playerFaction: currentPlayer.player.faction,
                  centerX: centerX,
                  centerY: centerY,
                  cellSize: cellSize,
                  availableSquares: availableSquares,
                  selectedPieceId: uiState.selectedPieceId,
                  selectedCityId: uiState.selectedCityId,
                  highlightPieceIds: _calculateHighlightPieces(uiState, virtualPieces, currentPlayer.player.faction),
                  dimmedPieceIds: pendingActions.whereType<PlaceAction>().map((a) => a.trayPieceId).toSet(),
                  showAvailableDots: !uiState.isBombarding,
                  onSquareTap: isPlanningMode 
                      ? (x, y) => _handleSquareTap(ref, x, y, uiState, virtualPieces, currentPlayer.player.faction, pendingActions, availableSquares)
                      : null,
                  onPieceTap: isPlanningMode
                      ? (piece) => _handlePieceTap(ref, piece, uiState, virtualPieces, currentPlayer.player.faction, pendingActions, availableSquares)
                      : null,
                  overlays: [
                     // Planned Bombardment Target Icons
                    ...virtualPieces.where((p) => p.x != null && p.y != null && visibleSquares.contains(math.Point(p.x!, p.y!)) && pendingActions.any((a) => a is BombardAction && a.targetId == p.id)).map((p) {
                      final pos = GameBoardBase.getRelativePosition(p.x!, p.y!, centerX, centerY);
                      return Positioned(
                        left: pos.x * cellSize + cellSize * 0.025,
                        top: pos.y * cellSize + cellSize * 0.025,
                        width: cellSize * 0.95,
                        height: cellSize * 0.95,
                        child: IgnorePointer(
                          child: Center(
                            child: BombardActionIcon(
                              size: cellSize * 0.9,
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // Bombardment Selection Border (Dashed)
                    ...virtualPieces.where((p) => p.x != null && p.y != null && uiState.isBombarding && availableSquares.contains(math.Point(p.x!, p.y!))).map((p) {
                       final pos = GameBoardBase.getRelativePosition(p.x!, p.y!, centerX, centerY);
                       return Positioned(
                        left: pos.x * cellSize + cellSize * 0.1,
                        top: pos.y * cellSize + cellSize * 0.1,
                        width: cellSize * 0.8,
                        height: cellSize * 0.8,
                        child: IgnorePointer(
                          child: CustomPaint(
                            size: Size(cellSize * 0.8, cellSize * 0.8),
                            painter: DashedCirclePainter(color: theme.colorScheme.primary, strokeWidth: 2),
                          ),
                        ),
                      );
                    }),

                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: TetherPainter(
                          pieces: virtualPieces,
                          faction: currentPlayer.player.faction,
                          centerX: centerX,
                          centerY: centerY,
                          cellSize: cellSize,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: MoveArrowPainter(
                          basePieces: pieces,
                          pendingActions: pendingActions,
                          faction: currentPlayer.player.faction,
                          centerX: centerX,
                          centerY: centerY,
                          cellSize: cellSize,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: BombardPainter(
                          basePieces: pieces,
                          pendingActions: pendingActions,
                          faction: currentPlayer.player.faction,
                          centerX: centerX,
                          centerY: centerY,
                          cellSize: cellSize,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading players: $e')),
    );
  }

  Set<String> _calculateHighlightPieces(GameplayUiState uiState, List<Piece> virtualPieces, Faction faction) {
    final highlights = <String>{};
    if (uiState.placingPieceId != null) {
      final placingPiece = virtualPieces.firstWhereOrNull((p) => p.id == uiState.placingPieceId);
      if (placingPiece != null && placingPiece.type.requiresTether && uiState.selectedCityId == null) {
        for (var piece in virtualPieces) {
           if (piece.type == PieceType.starCity && piece.faction == faction && piece.isAnchored) {
             final tetheredCount = virtualPieces.where((p) => p.tetheredToId == piece.id).length;
             if (tetheredCount < game.gameParameters.maxShipsPerCity) {
               highlights.add(piece.id);
             }
           }
        }
      }
    } else if (uiState.isRetethering && uiState.selectedPieceId != null) {
      final selectedPiece = virtualPieces.firstWhereOrNull((p) => p.id == uiState.selectedPieceId);
      if (selectedPiece != null) {
        for (var other in virtualPieces) {
          if (other.type == PieceType.starCity &&
              other.faction == faction &&
              other.isAnchored &&
              other.id != selectedPiece.tetheredToId) {
            final tetheredCount = virtualPieces.where((p) => p.tetheredToId == other.id).length;
            if (tetheredCount < game.gameParameters.maxShipsPerCity) {
              int dist = _getTorusDist(selectedPiece.x!, selectedPiece.y!, other.x!, other.y!);
              if (dist <= GameConstants.tetherRange) {
                highlights.add(other.id);
              }
            }
          }
        }
      }
    }
    return highlights;
  }

  List<Piece> _calculateVirtualPieces(List<Piece> basePieces, List<GameAction> actions) {
    var virtual = List<Piece>.from(basePieces);
    for (var action in actions) {
      if (action is PlaceAction) {
        int idx = virtual.indexWhere((p) => p.id == action.trayPieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(x: action.target.x, y: action.target.y, tetheredToId: action.cityId);
        }
      } else if (action is AnchorAction) {
        int idx = virtual.indexWhere((p) => p.id == action.pieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(isAnchored: action.isAnchored);
        }
      } else if (action is TetherAction) {
        int idx = virtual.indexWhere((p) => p.id == action.shipId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(tetheredToId: action.cityId);
        }
      }
    }
    return virtual;
  }

  Set<math.Point<int>> _calculateAvailableSquares(GameplayUiState uiState, List<Piece> pieces, Faction faction, List<GameAction> actions) {
    if (uiState.placingPieceId != null) {
      final piece = pieces.firstWhereOrNull((p) => p.id == uiState.placingPieceId);
      if (piece == null) return {};
      if (piece.type.requiresTether) {
        if (uiState.selectedCityId != null) {
          final city = pieces.firstWhereOrNull((p) => p.id == uiState.selectedCityId);
          if (city == null) return {};
          return _getAdjacentEmptySquares(city.x!, city.y!, pieces);
        }
      } else {
        final friendlyCities = pieces.where((p) => p.faction == faction && p.type == PieceType.starCity && p.x != null && p.isAnchored);
        final squares = <math.Point<int>>{};
        for (var city in friendlyCities) {
          squares.addAll(_getAdjacentEmptySquares(city.x!, city.y!, pieces));
        }
        return squares;
      }
    } else if (uiState.isBombarding && uiState.selectedPieceId != null) {
      final selectedPiece = pieces.firstWhereOrNull((p) => p.id == uiState.selectedPieceId);
      if (selectedPiece == null) return {};
      return _calculateAvailableBombardSquares(selectedPiece, pieces, faction, visibleSquares);
    } else if (uiState.isRetethering && uiState.selectedPieceId != null) {
      final piece = pieces.firstWhereOrNull((p) => p.id == uiState.selectedPieceId);
      if (piece == null) return {};
      final squares = <math.Point<int>>{};
      for (var other in pieces) {
        if (other.type == PieceType.starCity &&
            other.faction == faction &&
            other.isAnchored &&
            other.id != piece.tetheredToId) {
          final tetheredCount = pieces.where((p) => p.tetheredToId == other.id).length;
          if (tetheredCount < game.gameParameters.maxShipsPerCity) {
            int dist = _getTorusDist(piece.x!, piece.y!, other.x!, other.y!);
            if (dist <= GameConstants.tetherRange) {
              squares.add(math.Point(other.x!, other.y!));
            }
          }
        }
      }
      return squares;
    } else if (uiState.selectedPieceId != null) {
      final selectedPiece = pieces.firstWhereOrNull((p) => p.id == uiState.selectedPieceId);
      if (selectedPiece == null) return {};
      if (selectedPiece.type == PieceType.starCity) {
        if (selectedPiece.isAnchored) return {};
        if (actions.any((a) => a is AnchorAction && a.pieceId == selectedPiece.id)) return {};
      }
      if (actions.any((a) => a is PlaceAction && a.trayPieceId == selectedPiece.id)) return {};
      return _calculateAvailableMoves(selectedPiece, pieces, actions);
    }
    return {};
  }

  Set<math.Point<int>> _calculateAvailableBombardSquares(Piece piece, List<Piece> pieces, Faction faction, Set<math.Point<int>> visibleSquares) {
    final available = <math.Point<int>>{};
    const range = GameConstants.bombardRange;
    for (var other in pieces) {
      if (other.faction == faction) continue;
      if (other.x == null || other.y == null) continue;
      if (!other.isVisible) continue;
      if (!visibleSquares.contains(math.Point(other.x!, other.y!))) continue;
      int dist = _getTorusDist(piece.x!, piece.y!, other.x!, other.y!);
      if (dist <= range) {
        available.add(math.Point(other.x!, other.y!));
      }
    }
    return available;
  }

  Set<math.Point<int>> _calculateAvailableMoves(Piece piece, List<Piece> pieces, List<GameAction> actions) {
    final available = <math.Point<int>>{};
    final range = GameConstants.movementRange[piece.type] ?? 0;
    final startX = piece.x!;
    final startY = piece.y!;
    Piece? tetherCity;
    if (piece.type.requiresTether && piece.tetheredToId != null) {
      tetherCity = pieces.firstWhereOrNull((p) => p.id == piece.tetheredToId);
    }
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = (startX + dx) % 9;
        int ny = (startY + dy) % 9;
        if (nx < 0) nx += 9;
        if (ny < 0) ny += 9;
        if (game.stars.any((s) => s['x'] == nx && s['y'] == ny)) continue;
        if (tetherCity != null) {
           int tx = tetherCity.x!;
           int ty = tetherCity.y!;
           int dist = _getTorusDist(nx, ny, tx, ty);
           if (dist > GameConstants.tetherRange) continue;
        }
        bool isTargeted = actions.any((a) {
          if (a is MoveAction && a.pieceId != piece.id && a.to.x == nx && a.to.y == ny) return true;
          if (a is PlaceAction && a.target.x == nx && a.target.y == ny) return true;
          return false;
        });
        if (isTargeted) continue;
        available.add(math.Point(nx, ny));
      }
    }
    return available;
  }

  static int _getTorusDist(int x1, int y1, int x2, int y2) {
    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();
    if (dx > 4) dx = 9 - dx;
    if (dy > 4) dy = 9 - dy;
    return math.max(dx, dy);
  }

  Set<math.Point<int>> _getAdjacentEmptySquares(int x, int y, List<Piece> pieces) {
    final squares = <math.Point<int>>{};
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = (x + dx) % 9;
        int ny = (y + dy) % 9;
        if (nx < 0) nx += 9;
        if (ny < 0) ny += 9;
        if (!pieces.any((p) => p.x == nx && p.y == ny)) {
           if (!game.stars.any((s) => s['x'] == nx && s['y'] == ny)) {
             squares.add(math.Point(nx, ny));
           }
        }
      }
    }
    return squares;
  }

  void _handlePieceTap(WidgetRef ref, Piece piece, GameplayUiState uiState, List<Piece> virtualPieces, Faction faction, List<GameAction> actions, Set<math.Point<int>> availableSquares) {
    // Check if tapping a piece that was just placed to cancel placement
    final placeAction = actions.whereType<PlaceAction>().firstWhereOrNull((a) => a.trayPieceId == piece.id);
    if (placeAction != null) {
      ref.read(pendingActionsProvider(game.id).notifier).removePlacement(piece.id);
      ref.read(gameplayUiProvider(game.id).notifier).selectPiece(null);
      ref.read(gameplayUiProvider(game.id).notifier).resetPlacement();
      return;
    }

    if (piece.x != null && piece.y != null) {
      final target = math.Point(piece.x!, piece.y!);
      if (availableSquares.contains(target)) {
        if (uiState.isBombarding) {
          final notifier = ref.read(pendingActionsProvider(game.id).notifier);
          notifier.addOrReplaceAction(BombardAction(pieceId: uiState.selectedPieceId!, targetId: piece.id));
          ref.read(gameplayUiProvider(game.id).notifier).setBombarding(false);
          ref.read(gameplayUiProvider(game.id).notifier).selectPiece(null);
          return;
        }
        if (uiState.isRetethering) {
          final notifier = ref.read(pendingActionsProvider(game.id).notifier);
          notifier.addOrReplaceAction(TetherAction(shipId: uiState.selectedPieceId!, cityId: piece.id));
          ref.read(gameplayUiProvider(game.id).notifier).setRetethering(false);
          return;
        }
        _handleSquareTap(ref, piece.x!, piece.y!, uiState, virtualPieces, faction, actions, availableSquares);
        return;
      }
    }
    if (uiState.placingPieceId != null) {
       final placingPiece = virtualPieces.firstWhereOrNull((p) => p.id == uiState.placingPieceId);
       if (placingPiece != null && piece.type == PieceType.starCity && piece.faction == faction && piece.isAnchored) {
          if (placingPiece.type.requiresTether) {
            final tetheredCount = virtualPieces.where((p) => p.tetheredToId == piece.id).length;
            if (tetheredCount < game.gameParameters.maxShipsPerCity) {
              ref.read(gameplayUiProvider(game.id).notifier).setSelectedCity(piece.id);
              return;
            }
          } else {
            // For Neutrino/Star City, just select the city to show available squares around it
            ref.read(gameplayUiProvider(game.id).notifier).setSelectedCity(piece.id);
            return;
          }
       }
    }
    if (piece.faction == faction) {
      final isDeselecting = uiState.selectedPieceId == piece.id;
      if (isDeselecting) {
        ref.read(pendingActionsProvider(game.id).notifier).removeMovementAndBombardment(piece.id);
        ref.read(gameplayUiProvider(game.id).notifier).selectPiece(null);
      } else {
        bool isJustPlaced = actions.any((a) => a is PlaceAction && a.trayPieceId == piece.id);
        if (isJustPlaced) return;
        ref.read(gameplayUiProvider(game.id).notifier).selectPiece(piece.id);
      }
    }
  }

  void _handleSquareTap(WidgetRef ref, int x, int y, GameplayUiState uiState, List<Piece> pieces, Faction faction, List<GameAction> actions, Set<math.Point<int>> availableSquares) {
    final target = math.Point(x, y);
    if (availableSquares.contains(target)) {
      if (uiState.placingPieceId != null) {
        ref.read(pendingActionsProvider(game.id).notifier).addOrReplaceAction(
          PlaceAction(
            trayPieceId: uiState.placingPieceId!,
            cityId: uiState.selectedCityId,
            target: target,
          )
        );
        ref.read(gameplayUiProvider(game.id).notifier).resetPlacement();
      } else if (uiState.selectedPieceId != null) {
        if (uiState.isBombarding) return;
        final notifier = ref.read(pendingActionsProvider(game.id).notifier);
        notifier.addOrReplaceAction(MoveAction(pieceId: uiState.selectedPieceId!, to: target));
        ref.read(gameplayUiProvider(game.id).notifier).selectPiece(null);
      }
    } else {
      if (uiState.selectedPieceId != null || uiState.placingPieceId != null) {
        ref.read(gameplayUiProvider(game.id).notifier).selectPiece(null);
        ref.read(gameplayUiProvider(game.id).notifier).resetPlacement();
      }
    }
  }
}

class TetherPainter extends CustomPainter {
  final List<Piece> pieces;
  final Faction faction;
  final int centerX;
  final int centerY;
  final double cellSize;

  TetherPainter({
    required this.pieces,
    required this.faction,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faction.color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var piece in pieces) {
      if (piece.faction == faction && piece.tetheredToId != null && piece.x != null && piece.y != null) {
        final city = pieces.firstWhereOrNull((p) => p.id == piece.tetheredToId) ?? piece;
        if (city == piece || city.x == null || city.y == null) continue;
        final start = GameBoardBase.getDrawPos(piece.x!, piece.y!, centerX, centerY, cellSize);
        final end = GameBoardBase.getDrawPos(city.x!, city.y!, centerX, centerY, cellSize);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MoveArrowPainter extends CustomPainter {
  final List<Piece> basePieces;
  final List<GameAction> pendingActions;
  final Faction faction;
  final int centerX;
  final int centerY;
  final double cellSize;
  final Color color;

  MoveArrowPainter({
    required this.basePieces,
    required this.pendingActions,
    required this.faction,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var action in pendingActions) {
      if (action is MoveAction) {
        final piece = basePieces.firstWhereOrNull((p) => p.id == action.pieceId);
        if (piece == null || piece.faction != faction) continue;
        final start = GameBoardBase.getDrawPos(piece.x!, piece.y!, centerX, centerY, cellSize);
        final end = GameBoardBase.getDrawPos(action.to.x, action.to.y, centerX, centerY, cellSize);
        _drawArrow(canvas, start, end, paint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 16.0; 
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

class BombardPainter extends CustomPainter {
  final List<Piece> basePieces;
  final List<GameAction> pendingActions;
  final Faction faction;
  final int centerX;
  final int centerY;
  final double cellSize;
  final Color color;

  BombardPainter({
    required this.basePieces,
    required this.pendingActions,
    required this.faction,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var action in pendingActions) {
      if (action is BombardAction) {
        final attacker = basePieces.firstWhereOrNull((p) => p.id == action.pieceId);
        final target = basePieces.firstWhereOrNull((p) => p.id == action.targetId);
        if (attacker == null || target == null || attacker.faction != faction) continue;
        final start = GameBoardBase.getDrawPos(attacker.x!, attacker.y!, centerX, centerY, cellSize);
        final end = GameBoardBase.getDrawPos(target.x!, target.y!, centerX, centerY, cellSize);
        _drawDashedLine(canvas, start, end, linePaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double distance = (end - start).distance;
    double currentDistance = 0;
    final direction = (end - start) / distance;
    while (currentDistance < distance) {
      canvas.drawLine(
        start + direction * currentDistance,
        start + direction * math.min(currentDistance + dashWidth, distance),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashWidth = 4.0;
    const dashSpace = 2.0;
    final circumference = 2 * math.pi * radius;
    final totalDashes = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < totalDashes; i++) {
      final startAngle = i * (dashWidth + dashSpace) / radius;
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
