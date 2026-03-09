import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/lobby/models/game.dart' as models;
import 'package:star_cities/features/game/widgets/game_planning_board.dart';
import 'package:star_cities/features/game/widgets/game_replay_board.dart';

class GameBoard extends StatelessWidget {
  final models.Game game;
  final List<Piece> pieces;
  final Set<math.Point<int>> visibleSquares;
  final bool isPlanning;
  final List<GameEvent> events;

  const GameBoard({
    super.key,
    required this.game,
    required this.pieces,
    required this.visibleSquares,
    this.isPlanning = false,
    this.events = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (isPlanning) {
      return GamePlanningBoard(
        game: game,
        pieces: pieces,
        visibleSquares: visibleSquares,
      );
    } else {
      return GameReplayBoard(
        game: game,
        pieces: pieces,
        visibleSquares: visibleSquares,
        events: events,
      );
    }
  }
}
