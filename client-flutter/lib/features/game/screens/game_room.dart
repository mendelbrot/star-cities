import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/shared/widgets/game_settings_row.dart';
import 'package:star_cities/features/game/widgets/section_title.dart';
import 'package:star_cities/features/game/widgets/player_list_item.dart';
import 'package:star_cities/features/game/widgets/game_room_controls.dart';

class GameRoom extends ConsumerWidget {
  final Game game;
  const GameRoom({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersWithProfilesAsync = ref.watch(gamePlayersWithProfilesProvider(game.id));
    final supabase = ref.watch(supabaseClientProvider);
    final theme = Theme.of(context);

    return playersWithProfilesAsync.when(
      data: (players) {
        final currentUser = supabase.auth.currentUser;
        final currentPlayer = players.where((p) => p.player.userId == currentUser?.id).toList();
        final isJoined = currentPlayer.isNotEmpty;
        final canJoin = players.length < game.playerCount && !isJoined;
        final takenFactions = players.map((p) => p.player.faction).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: SectionTitle('players (${players.length}/${game.playerCount})')),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GameSettingsRow(game: game),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...players.map((p) {
              final isCurrentPlayer = p.player.userId == currentUser?.id;
              final availableForChange = Faction.values
                  .where((f) => !takenFactions.contains(f) || f == p.player.faction)
                  .toList();

              return PlayerListItem(
                playerWithProfile: p,
                availableFactions: availableForChange,
                isCurrentPlayer: isCurrentPlayer,
              );
            }),
            const SizedBox(height: 32),
            GameRoomControls(
              gameId: game.id,
              isJoined: isJoined,
              canJoin: canJoin,
              canAddBot: players.length < game.playerCount,
              currentPlayerId: isJoined ? currentPlayer.first.player.id : null,
            ),
            const SizedBox(height: 48),
            Text(
              'The game will start when all player spots are filled',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ],
        );
      },
      loading: () => const Center(child: GridLoadingIndicator(size: 40)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
