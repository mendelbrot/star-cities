import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/game/providers/game_controller.dart';

class GameRoomControls extends ConsumerWidget {
  final String gameId;
  final bool isJoined;
  final bool canJoin;
  final bool canAddBot;
  final String? currentPlayerId;

  const GameRoomControls({
    super.key,
    required this.gameId,
    required this.isJoined,
    required this.canJoin,
    required this.canAddBot,
    this.currentPlayerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(gameControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isJoined && currentPlayerId != null)
          OutlinedButton.icon(
            onPressed: () => controller.removePlayer(currentPlayerId!),
            icon: const Icon(LucideIcons.userMinus),
            label: const Text('Leave Game'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
          )
        else if (canJoin)
          OutlinedButton.icon(
            onPressed: () => controller.joinGame(gameId),
            icon: const Icon(LucideIcons.userPlus),
            label: const Text('Join Game'),
          ),
        if (canAddBot) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => controller.addBot(gameId),
            icon: const Icon(LucideIcons.bot),
            label: const Text('Add Bot Player'),
          ),
        ],
      ],
    );
  }
}
