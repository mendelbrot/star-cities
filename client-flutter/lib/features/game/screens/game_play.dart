import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/widgets/game_settings_row.dart';

class GamePlay extends ConsumerWidget {
  final Game game;
  const GamePlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameSettingsRow(game: game),
              const SizedBox(height: 32),
              const Center(child: Text('Scoreboard & Status')),
            ],
          ),
        ),
        const Center(child: Text('Previous Turn Replay')),
        const Center(child: Text('Move Planning Grid')),
      ],
    );
  }
}
