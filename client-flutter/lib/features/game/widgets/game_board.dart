import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_actions.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/utils/game_constants.dart';
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
    final uiState = ref.watch(gameplayUiProvider);
    final pendingActions = ref.watch(pendingActionsProvider(game.id));

    return playersAsync.when(
      data: (players) {
        final currentPlayer = players.firstWhere(
          (p) => p.player.userId == currentUser?.id,
          orElse: () => players.first,
        );
        final homeStar = currentPlayer.player.homeStar;
        final centerX = homeStar?['x'] ?? 4;
        final centerY = homeStar?['y'] ?? 4;

        // Effective State: Turn State + Pending Actions
        final virtualPieces = _calculateVirtualPieces(pieces, pendingActions);
        final availableSquares = _calculateAvailableSquares(uiState, virtualPieces, currentPlayer.player.faction, pendingActions);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, constraints.maxHeight);
              final cellSize = size / 9;

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

                      // Tether Lines (Local Faction Only)
                      CustomPaint(
                        size: Size(size, size),
                        painter: TetherPainter(
                          pieces: virtualPieces,
                          faction: currentPlayer.player.faction,
                          centerX: centerX,
                          centerY: centerY,
                          cellSize: cellSize,
                        ),
                      ),

                      // Move Arrows
                      CustomPaint(
                        size: Size(size, size),
                        painter: MoveArrowPainter(
                          basePieces: pieces,
                          pendingActions: pendingActions,
                          faction: currentPlayer.player.faction,
                          centerX: centerX,
                          centerY: centerY,
                          cellSize: cellSize,
                        ),
                      ),

                      // Clickable Grid Squares
                      ...List.generate(81, (i) {
                        final x = i % 9;
                        final y = i ~/ 9;
                        final pos = _getRelativePosition(x, y, centerX, centerY);
                        final isAvailable = availableSquares.contains(math.Point(x, y));

                        return Positioned(
                          left: pos.x * cellSize,
                          top: pos.y * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => _handleSquareTap(ref, x, y, uiState, virtualPieces, currentPlayer.player.faction, pendingActions),
                            child: Container(
                              color: Colors.transparent,
                              child: isAvailable 
                                ? Center(
                                    child: Container(
                                      width: cellSize * 0.3,
                                      height: cellSize * 0.3,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                            ),
                          ),
                        );
                      }),
                      
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

                      // Pieces
                      ...virtualPieces.where((piece) => piece.x != null && piece.y != null && (piece.isVisible || piece.faction == currentPlayer.player.faction) && visibleSquares.contains(math.Point(piece.x!, piece.y!))).map((piece) {
                        final pos = _getRelativePosition(piece.x!, piece.y!, centerX, centerY);
                        final isSelected = uiState.selectedPieceId == piece.id || uiState.selectedCityId == piece.id;
                        final isPendingPlace = pendingActions.any((a) => a is PlaceAction && a.trayPieceId == piece.id);
                        final isPendingMove = pendingActions.any((a) => a is MoveAction && a.pieceId == piece.id);
                        
                        final isSelectableCity = _isCitySelectableForPlacement(uiState, piece, virtualPieces, currentPlayer.player.faction);

                        return Positioned(
                          left: pos.x * cellSize + cellSize * 0.1,
                          top: pos.y * cellSize + cellSize * 0.1,
                          width: cellSize * 0.8,
                          height: cellSize * 0.8,
                          child: GestureDetector(
                            onTap: () => _handlePieceTap(ref, piece, uiState, virtualPieces, currentPlayer.player.faction, pendingActions, availableSquares),
                            child: Opacity(
                              opacity: (isPendingPlace || isPendingMove) ? 0.6 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: (isSelected || isSelectableCity) ? Colors.white : Colors.transparent,
                                    width: (isSelected || isSelectableCity) ? 2 : 0,
                                  ),
                                  borderRadius: BorderRadius.circular(cellSize * 0.1),
                                ),
                                child: ShipIcon(
                                  type: piece.type,
                                  faction: piece.faction,
                                  size: cellSize * 0.8,
                                  isAnchored: piece.isAnchored,
                                ),
                              ),
                            ),
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading players: $e')),
    );
  }

  bool _isCitySelectableForPlacement(GameplayUiState uiState, Piece piece, List<Piece> virtualPieces, Faction faction) {
    if (uiState.placingPieceId == null) return false;
    final placingPiece = virtualPieces.firstWhere((p) => p.id == uiState.placingPieceId);
    if (!placingPiece.type.requiresTether) return false;
    if (uiState.selectedCityId != null) return false;

    // Must be a friendly anchored star city with capacity
    if (piece.type == PieceType.starCity && piece.faction == faction && piece.isAnchored) {
       final tetheredCount = virtualPieces.where((p) => p.tetheredToId == piece.id).length;
       return tetheredCount < game.gameParameters.maxShipsPerCity;
    }
    return false;
  }

  List<Piece> _calculateVirtualPieces(List<Piece> basePieces, List<GameAction> actions) {
    var virtual = List<Piece>.from(basePieces);
    for (var action in actions) {
      if (action is PlaceAction) {
        int idx = virtual.indexWhere((p) => p.id == action.trayPieceId);
        if (idx != -1) {
          virtual[idx] = virtual[idx].copyWith(x: action.target.x, y: action.target.y, tetheredToId: action.cityId);
        }
      } else if (action is MoveAction) {
        // Pieces stay put visually during planning
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
      final piece = pieces.firstWhere((p) => p.id == uiState.placingPieceId);
      if (piece.type.requiresTether) {
        if (uiState.selectedCityId != null) {
          final city = pieces.firstWhere((p) => p.id == uiState.selectedCityId);
          return _getAdjacentEmptySquares(city.x!, city.y!, pieces);
        }
      } else {
        // Star City or Neutrino - adjacent to ANY friendly city
        final friendlyCities = pieces.where((p) => p.faction == faction && p.type == PieceType.starCity && p.x != null);
        final squares = <math.Point<int>>{};
        for (var city in friendlyCities) {
          squares.addAll(_getAdjacentEmptySquares(city.x!, city.y!, pieces));
        }
        return squares;
      }
    } else if (uiState.selectedPieceId != null) {
      // Handle Movement
      final selectedPiece = pieces.firstWhere((p) => p.id == uiState.selectedPieceId);
      // Anchor cities can't move if anchored.
      if (selectedPiece.type == PieceType.starCity && selectedPiece.isAnchored) return {};
      
      // Just placed pieces can't move
      if (actions.any((a) => a is PlaceAction && a.trayPieceId == selectedPiece.id)) return {};

      return _calculateAvailableMoves(selectedPiece, pieces, actions);
    }
    return {};
  }

  Set<math.Point<int>> _calculateAvailableMoves(Piece piece, List<Piece> pieces, List<GameAction> actions) {
    final available = <math.Point<int>>{};
    final range = GameConstants.movementRange[piece.type] ?? 0;
    
    // Original position for movement range calculation
    final startX = piece.x!;
    final startY = piece.y!;

    // For tethered units, they must stay within range of their city
    Piece? tetherCity;
    if (piece.type.requiresTether && piece.tetheredToId != null) {
      tetherCity = pieces.firstWhere((p) => p.id == piece.tetheredToId);
    }

    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        if (dx == 0 && dy == 0) continue;
        
        int nx = (startX + dx) % 9;
        int ny = (startY + dy) % 9;
        if (nx < 0) nx += 9;
        if (ny < 0) ny += 9;

        // Constraint: Not a star
        if (game.stars.any((s) => s['x'] == nx && s['y'] == ny)) continue;

        // Constraint: Tether range
        if (tetherCity != null) {
           int tx = tetherCity.x!;
           int ty = tetherCity.y!;
           int dist = _getTorusDist(nx, ny, tx, ty);
           if (dist > GameConstants.tetherRange) continue;
        }

        // Constraint: Must not be the movement target of another friendly unit
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

  int _getTorusDist(int x1, int y1, int x2, int y2) {
    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();
    if (dx > 4) dx = 9 - dx;
    if (dy > 4) dy = 9 - dy;
    return math.max(dx, dy); // Chess distance (Chebyshev)
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
        
        // Check if square is empty
        if (!pieces.any((p) => p.x == nx && p.y == ny)) {
           // Also check if it's a star (using game.stars)
           if (!game.stars.any((s) => s['x'] == nx && s['y'] == ny)) {
             squares.add(math.Point(nx, ny));
           }
        }
      }
    }
    return squares;
  }

  void _handlePieceTap(WidgetRef ref, Piece piece, GameplayUiState uiState, List<Piece> virtualPieces, Faction faction, List<GameAction> actions, Set<math.Point<int>> availableSquares) {
    // If we're tapping a piece on an available square, treat it as a move/placement target
    if (piece.x != null && piece.y != null) {
      final target = math.Point(piece.x!, piece.y!);
      if (availableSquares.contains(target)) {
        _handleSquareTap(ref, piece.x!, piece.y!, uiState, virtualPieces, faction, actions);
        return;
      }
    }

    if (uiState.placingPieceId != null) {
      if (_isCitySelectableForPlacement(uiState, piece, virtualPieces, faction)) {
        ref.read(gameplayUiProvider.notifier).setSelectedCity(piece.id);
        return;
      }
    }

    if (piece.faction == faction) {
      // Check if just placed - can't move or act
      bool isJustPlaced = actions.any((a) => a is PlaceAction && a.trayPieceId == piece.id);
      if (isJustPlaced) return;

      ref.read(gameplayUiProvider.notifier).selectPiece(uiState.selectedPieceId == piece.id ? null : piece.id);
    }
  }

  void _handleSquareTap(WidgetRef ref, int x, int y, GameplayUiState uiState, List<Piece> pieces, Faction faction, List<GameAction> actions) {
    final target = math.Point(x, y);
    final available = _calculateAvailableSquares(uiState, pieces, faction, actions);
    
    if (available.contains(target)) {
      if (uiState.placingPieceId != null) {
        ref.read(pendingActionsProvider(game.id).notifier).addAction(
          PlaceAction(
            trayPieceId: uiState.placingPieceId!,
            cityId: uiState.selectedCityId,
            target: target,
          )
        );
        ref.read(gameplayUiProvider.notifier).resetPlacement();
      } else if (uiState.selectedPieceId != null) {
        // Create MoveAction
        final notifier = ref.read(pendingActionsProvider(game.id).notifier);
        notifier.removeAction(uiState.selectedPieceId!);
        notifier.addAction(
          MoveAction(pieceId: uiState.selectedPieceId!, to: target)
        );
        ref.read(gameplayUiProvider.notifier).selectPiece(null);
      }
    } else {
      // Tap on illegal square cancels selection
      if (uiState.selectedPieceId != null || uiState.placingPieceId != null) {
        ref.read(gameplayUiProvider.notifier).selectPiece(null);
        ref.read(gameplayUiProvider.notifier).resetPlacement();
      }
    }
  }

  math.Point<int> _getRelativePosition(int x, int y, int centerX, int centerY) {
    int relX = (x - centerX + 4) % 9;
    int relY = (y - centerY + 4) % 9;
    if (relX < 0) relX += 9;
    if (relY < 0) relY += 9;
    return math.Point(relX, relY);
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
        final city = pieces.firstWhere((p) => p.id == piece.tetheredToId, orElse: () => piece);
        if (city == piece || city.x == null || city.y == null) continue;

        final start = _getDrawPos(piece.x!, piece.y!);
        final end = _getDrawPos(city.x!, city.y!);

        canvas.drawLine(start, end, paint);
      }
    }
  }

  Offset _getDrawPos(int x, int y) {
    int relX = (x - centerX + 4) % 9;
    int relY = (y - centerY + 4) % 9;
    if (relX < 0) relX += 9;
    if (relY < 0) relY += 9;
    return Offset(relX * cellSize + cellSize / 2, relY * cellSize + cellSize / 2);
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

  MoveArrowPainter({
    required this.basePieces,
    required this.pendingActions,
    required this.faction,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var action in pendingActions) {
      if (action is MoveAction) {
        final piece = basePieces.firstWhere((p) => p.id == action.pieceId);
        if (piece.faction != faction) continue;

        final start = _getDrawPos(piece.x!, piece.y!);
        final end = _getDrawPos(action.to.x, action.to.y);

        _drawArrow(canvas, start, end, paint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Check for torus wrap (don't draw arrow across the board if wrapping)
    if ((start.dx - end.dx).abs() > cellSize * 4.5 || (start.dy - end.dy).abs() > cellSize * 4.5) {
      // For now, just skip drawing arrows that wrap.
      // In a more complex implementation, we'd draw two partial arrows.
      return;
    }

    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 8.0;
    
    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(end.dx - arrowSize * math.cos(angle - math.pi / 6), end.dy - arrowSize * math.sin(angle - math.pi / 6));
    path.lineTo(end.dx - arrowSize * math.cos(angle + math.pi / 6), end.dy - arrowSize * math.sin(angle + math.pi / 6));
    path.close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  Offset _getDrawPos(int x, int y) {
    int relX = (x - centerX + 4) % 9;
    int relY = (y - centerY + 4) % 9;
    if (relX < 0) relX += 9;
    if (relY < 0) relY += 9;
    return Offset(relX * cellSize + cellSize / 2, relY * cellSize + cellSize / 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
