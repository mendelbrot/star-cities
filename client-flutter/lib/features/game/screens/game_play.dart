import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/widgets/game_settings_row.dart';
import 'package:star_cities/features/game/widgets/game_board.dart';
import 'package:star_cities/features/game/widgets/section_title.dart';

class GamePlay extends ConsumerWidget {
  final Game game;
  const GamePlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      children: [
        // Tab 1: Players / Scoreboard
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameSettingsRow(game: game),
              const SizedBox(height: 32),
              const SectionTitle('scoreboard'),
              const Expanded(child: Center(child: Text('Scoreboard content will go here'))),
            ],
          ),
        ),
        
        // Tab 2: Replay
        Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameBoard(game: game),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Replay Controls (Coming Soon)'),
            ),
          ],
        ),

        // Tab 3: Planning
        Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameBoard(game: game),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Planning Tray (Coming Soon)'),
            ),
          ],
        ),
      ],
    );
  }
}
