import 'dart:math' as math;
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/utils/game_constants.dart';
import 'package:star_cities/shared/models/faction.dart';

Set<math.Point<int>> calculateVisibleSquares(List<Piece> pieces, Faction playerFaction) {
  final visibleSet = <math.Point<int>>{};

  for (final piece in pieces) {
    if (piece.faction != playerFaction) continue;
    if (piece.x == null || piece.y == null) continue;

    final range = GameConstants.visionRange[piece.type] ?? 0;

    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        // Torus wrapping
        int vx = (piece.x! + dx) % GameConstants.gridSize;
        int vy = (piece.y! + dy) % GameConstants.gridSize;
        if (vx < 0) vx += GameConstants.gridSize;
        if (vy < 0) vy += GameConstants.gridSize;
        
        visibleSet.add(math.Point(vx, vy));
      }
    }
  }

  return visibleSet;
}
