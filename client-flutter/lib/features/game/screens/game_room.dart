import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';
import 'package:star_cities/shared/widgets/game_settings_row.dart';

class GameRoom extends ConsumerStatefulWidget {
  final String gameId;
  const GameRoom({super.key, required this.gameId});

  @override
  ConsumerState<GameRoom> createState() => _GameRoomState();
}

class _GameRoomState extends ConsumerState<GameRoom> {
  final _supabase = Supabase.instance.client;

  Future<void> _addBot() async {
    try {
      final playersAsync = ref.read(playersProvider(widget.gameId));
      final players = playersAsync.value ?? [];
      final takenFactions = players.map((p) => p.faction).toList();
      final availableFactions = Faction.values.where((f) => !takenFactions.contains(f)).toList();
      
      if (availableFactions.isEmpty) return;
      
      final randomFaction = availableFactions[math.Random().nextInt(availableFactions.length)];
      
      final botNames = [
        'R2-D2',
        'C-3PO',
        'HAL 9000',
        'Data',
        'TARS',
        'Skynet',
        'Deep Blue',
      ];
      final randomName = botNames[math.Random().nextInt(botNames.length)];

      await _supabase.from('players').insert({
        'game_id': widget.gameId,
        'is_bot': true,
        'bot_name': randomName,
        'faction': randomFaction.value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _removePlayer(String playerId) async {
    try {
      await _supabase.from('players').delete().eq('id', playerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _joinGame() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final playersAsync = ref.read(playersProvider(widget.gameId));
      final players = playersAsync.value ?? [];
      final takenFactions = players.map((p) => p.faction).toList();
      final availableFactions = Faction.values.where((f) => !takenFactions.contains(f)).toList();

      if (availableFactions.isEmpty) return;
      
      final randomFaction = availableFactions[math.Random().nextInt(availableFactions.length)];

      await _supabase.from('players').insert({
        'game_id': widget.gameId,
        'user_id': user.id,
        'faction': randomFaction.value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _changeFaction(String playerId, Faction newFaction) async {
    try {
      await _supabase
          .from('players')
          .update({'faction': newFaction.value})
          .eq('id', playerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for game deletion to redirect to lobby
    ref.listen<AsyncValue<Game?>>(gameProvider(widget.gameId), (previous, next) {
      if (next is AsyncData && next.value == null) {
        if (mounted && GoRouterState.of(context).uri.toString().contains(widget.gameId)) {
          context.go('/');
        }
      }
    });

    final gameAsync = ref.watch(gameProvider(widget.gameId));

    return gameAsync.when(
      data: (game) {
        if (game == null) return const Scaffold(body: Center(child: Text('Game not found.')));
        
        final scaffold = Scaffold(
          appBar: _buildAppBar(game),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: game.status == GameStatus.waiting 
                    ? _buildWaitingUI(game) 
                    : _buildActiveUI(game),
              ),
            ),
          ),
        );

        if (game.status != GameStatus.waiting) {
          return DefaultTabController(
            length: 3,
            child: scaffold,
          );
        }
        
        return scaffold;
      },
      loading: () => const Scaffold(body: Center(child: GridLoadingIndicator(size: 60))),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  PreferredSizeWidget _buildAppBar(Game game) {
    final theme = Theme.of(context);
    final title = game.status == GameStatus.waiting
        ? 'Game Room: ${game.id.substring(0, 8)}'
        : 'Turn ${game.turnNumber} | ${game.status.value}';

    return AppBar(
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.go('/'),
        tooltip: 'Back to Lobby',
      ),
      title: Text(title),
      bottom: game.status == GameStatus.waiting
          ? null
          : TabBar(
              unselectedLabelColor: theme.disabledColor,
              tabs: const [
                Tab(text: 'Players'),
                Tab(text: 'Replay'),
                Tab(text: 'Planning'),
              ],
            ),
    );
  }

  Widget _buildWaitingUI(Game game) {
    final playersWithProfilesAsync = ref.watch(gamePlayersWithProfilesProvider(widget.gameId));
    final theme = Theme.of(context);

    return playersWithProfilesAsync.when(
      data: (players) {
        final currentUser = _supabase.auth.currentUser;
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
                Expanded(child: _buildSectionTitle('players (${players.length}/${game.playerCount})')),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16), // Match _buildSectionTitle bottom padding
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

              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        // Left: Ship icon and name
                        Expanded(
                          child: Row(
                            children: [
                              ShipIcon(
                                type: PieceType.starCity,
                                faction: p.player.faction,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Center: Faction color selector (now right-aligned in its section)
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PopupMenuButton<Faction>(
                                enabled: isCurrentPlayer || p.player.isBot,
                                onSelected: (faction) => _changeFaction(p.player.id, faction),
                                itemBuilder: (context) => availableForChange.map((f) => PopupMenuItem(
                                  value: f,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: f.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(f.value),
                                    ],
                                  ),
                                )).toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.disabledColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Faction: ${p.player.faction.value}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isCurrentPlayer || p.player.isBot 
                                          ? theme.primaryColor 
                                          : theme.disabledColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right: X or placeholder
                              p.player.isBot 
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 20),
                                    onPressed: () => _removePlayer(p.player.id),
                                    tooltip: 'Remove Bot',
                                  )
                                : const IconButton(
                                    icon: Opacity(
                                      opacity: 0,
                                      child: Icon(LucideIcons.x, size: 20),
                                    ),
                                    onPressed: null,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            if (isJoined)
              OutlinedButton.icon(
                onPressed: () => _removePlayer(currentPlayer.first.player.id),
                icon: const Icon(LucideIcons.userMinus),
                label: const Text('Leave Game'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              )
            else if (canJoin)
              OutlinedButton.icon(
                onPressed: _joinGame,
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('Join Game'),
              ),
            if (players.length < game.playerCount) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addBot,
                icon: const Icon(LucideIcons.bot),
                label: const Text('Add Bot Player'),
              ),
            ],
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

  Widget _buildActiveUI(Game game) {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }
}
