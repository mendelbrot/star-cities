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
  final Map<int, List<Piece>> snapshots;

  const GameBoard({
    super.key,
    required this.game,
    required this.pieces,
    required this.visibleSquares,
    this.isPlanning = false,
    this.events = const [],
    this.snapshots = const {},
  });

  @override
  Widget build(BuildContext context) {
    Widget board;
    if (isPlanning) {
      board = GamePlanningBoard(
        game: game,
        pieces: pieces,
        visibleSquares: visibleSquares,
      );
    } else {
      board = GameReplayBoard(
        game: game,
        pieces: pieces,
        visibleSquares: visibleSquares,
        events: events,
        snapshots: snapshots,
      );
    }

    return board;
  }
}
