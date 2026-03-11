import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/icon_widgets/ship_icon.dart';

class GameBoardBase extends StatelessWidget {
  final List<Map<String, int>> stars;
  final List<Piece> pieces;
  final Set<math.Point<int>> visibleSquares;
  final Faction playerFaction;
  final int centerX;
  final int centerY;
  final double cellSize;
  final Set<math.Point<int>> availableSquares;
  final String? selectedPieceId;
  final String? selectedCityId;
  final Set<String> highlightPieceIds;
  final Set<String> dimmedPieceIds;
  final bool showAvailableDots;
  final Function(int x, int y)? onSquareTap;
  final Function(Piece piece)? onPieceTap;
  final List<Widget> overlays;

  const GameBoardBase({
    super.key,
    required this.stars,
    required this.pieces,
    required this.visibleSquares,
    required this.playerFaction,
    required this.centerX,
    required this.centerY,
    required this.cellSize,
    this.availableSquares = const {},
    this.selectedPieceId,
    this.selectedCityId,
    this.highlightPieceIds = const {},
    this.dimmedPieceIds = const {},
    this.showAvailableDots = true,
    this.onSquareTap,
    this.onPieceTap,
    this.overlays = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // 1. Grid lines
        ...List.generate(10, (i) => Positioned(
          left: i * cellSize,
          top: 0,
          bottom: 0,
          child: IgnorePointer(child: Container(width: 1, color: theme.dividerColor.withValues(alpha: 0.1))),
        )),
        ...List.generate(10, (i) => Positioned(
          top: i * cellSize,
          left: 0,
          right: 0,
          child: IgnorePointer(child: Container(height: 1, color: theme.dividerColor.withValues(alpha: 0.1))),
        )),

        // 2. Clickable Grid Squares (with selection dots)
        ...List.generate(81, (i) {
          final x = i % 9;
          final y = i ~/ 9;
          final pos = getRelativePosition(x, y, centerX, centerY);
          final isAvailable = availableSquares.contains(math.Point(x, y));

          return Positioned(
            left: pos.x * cellSize,
            top: pos.y * cellSize,
            width: cellSize,
            height: cellSize,
            child: GestureDetector(
              onTap: onSquareTap != null ? () => onSquareTap!(x, y) : null,
              child: Container(
                color: Colors.transparent,
                child: (isAvailable && showAvailableDots)
                ? Center(
                    child: Container(
                      width: cellSize * 0.3,
                      height: cellSize * 0.3,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  : null,
              ),
            ),
          );
        }),
        
        // 3. Stars (only if visible)
        ...stars.where((star) => visibleSquares.contains(math.Point(star['x']!, star['y']!))).map((star) {
          final pos = getRelativePosition(star['x']!, star['y']!, centerX, centerY);
          return Positioned(
            left: pos.x * cellSize + cellSize * 0.25,
            top: pos.y * cellSize + cellSize * 0.25,
            width: cellSize * 0.5,
            height: cellSize * 0.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),

        // 4. Pieces
        ...pieces.where((piece) => piece.x != null && piece.y != null && (piece.isVisible || piece.faction == playerFaction) && visibleSquares.contains(math.Point(piece.x!, piece.y!))).map((piece) {
          final pos = getRelativePosition(piece.x!, piece.y!, centerX, centerY);
          final isSelected = selectedPieceId == piece.id || selectedCityId == piece.id;
          final isHighlighted = highlightPieceIds.contains(piece.id);
          final isDimmed = dimmedPieceIds.contains(piece.id);

          return Positioned(
            left: pos.x * cellSize + cellSize * 0.1,
            top: pos.y * cellSize + cellSize * 0.1,
            width: cellSize * 0.8,
            height: cellSize * 0.8,
            child: GestureDetector(
              onTap: onPieceTap != null ? () => onPieceTap!(piece) : null,
              child: Opacity(
                opacity: isDimmed ? 0.3 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (isSelected || isHighlighted) ? theme.colorScheme.primary : Colors.transparent,
                      width: (isSelected || isHighlighted) ? 2 : 0,
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

        // 5. Fog of War Overlay
        ...List.generate(81, (i) {
          final x = i % 9;
          final y = i ~/ 9;
          if (visibleSquares.contains(math.Point(x, y))) return const SizedBox.shrink();

          final pos = getRelativePosition(x, y, centerX, centerY);
          return Positioned(
            left: pos.x * cellSize,
            top: pos.y * cellSize,
            width: cellSize,
            height: cellSize,
            child: IgnorePointer(
              child: Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          );
        }),

        // 6. Custom Overlays
        ...overlays,
      ],
    );
  }

  static math.Point<int> getRelativePosition(int x, int y, int centerX, int centerY) {
    int relX = (x - centerX + 4) % 9;
    int relY = (y - centerY + 4) % 9;
    if (relX < 0) relX += 9;
    if (relY < 0) relY += 9;
    return math.Point(relX, relY);
  }

  static Offset getDrawPos(int x, int y, int centerX, int centerY, double cellSize) {
    final rel = getRelativePosition(x, y, centerX, centerY);
    return Offset(rel.x * cellSize + cellSize / 2, rel.y * cellSize + cellSize / 2);
  }
}
