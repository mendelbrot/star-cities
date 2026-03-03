import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/features/game/presentation/providers/game_providers.dart';
import 'package:star_cities/shared/models/player.dart';
import 'package:go_router/go_router.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';

class GameBoard extends ConsumerStatefulWidget {
  final String gameId;
  const GameBoard({super.key, required this.gameId});

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> {
  final _supabase = Supabase.instance.client;

  Future<void> _addBot() async {
    try {
      final playersAsync = ref.read(playersProvider(widget.gameId));
      final players = playersAsync.value ?? [];
      final takenFactions = players.map((p) => p.faction.value).toList();
      final allFactions = ['BLUE', 'RED', 'PURPLE', 'GREEN'];
      final availableFaction = allFactions.firstWhere((f) => !takenFactions.contains(f));

      await _supabase.from('players').insert({
        'game_id': widget.gameId,
        'is_bot': true,
        'bot_name': 'BOT $availableFaction',
        'faction': availableFaction,
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
      final takenFactions = players.map((p) => p.faction.value).toList();
      final allFactions = ['BLUE', 'RED', 'PURPLE', 'GREEN'];
      final availableFaction = allFactions.firstWhere((f) => !takenFactions.contains(f));

      await _supabase.from('players').insert({
        'game_id': widget.gameId,
        'user_id': user.id,
        'faction': availableFaction,
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
        if (game == null) return const Scaffold(body: Center(child: Text('GAME NOT FOUND.')));
        if (game.status == GameStatus.waiting) return _buildWaitingUI(game);
        return _buildActiveUI(game);
      },
      loading: () => const Scaffold(body: Center(child: GridLoadingIndicator(size: 60))),
      error: (e, s) => Scaffold(body: Center(child: Text('ERROR: $e'))),
    );
  }

  Widget _buildWaitingUI(Game game) {
    final playersWithProfilesAsync = ref.watch(gamePlayersWithProfilesProvider(widget.gameId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('GAME ROOM: ${game.id.substring(0, 8)}'),
      ),
      body: playersWithProfilesAsync.when(
        data: (players) {
          final currentUser = _supabase.auth.currentUser;
          final currentPlayer = players.where((p) => p.player.userId == currentUser?.id).toList();
          final isJoined = currentPlayer.isNotEmpty;
          final canJoin = players.length < game.playerCount && !isJoined;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('PLAYERS (${players.length}/${game.playerCount})'),
              ...players.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getFactionColor(p.player.faction),
                    radius: 6,
                  ),
                  title: Text(p.displayName),
                  subtitle: Text('FACTION: ${p.player.faction.value}'),
                  trailing: p.player.isBot 
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => _removePlayer(p.player.id),
                        tooltip: 'REMOVE BOT',
                      )
                    : null,
                ),
              )),
              const SizedBox(height: 32),
              if (isJoined)
                OutlinedButton.icon(
                  onPressed: () => _removePlayer(currentPlayer.first.player.id),
                  icon: const Icon(LucideIcons.userMinus),
                  label: const Text('LEAVE GAME'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                )
              else if (canJoin)
                OutlinedButton.icon(
                  onPressed: _joinGame,
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text('JOIN GAME'),
                ),
              if (players.length < game.playerCount) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addBot,
                  icon: const Icon(LucideIcons.bot),
                  label: const Text('ADD BOT PLAYER'),
                ),
              ],
              const SizedBox(height: 48),
              Text(
                'THE MISSION WILL BEGIN AUTOMATICALLY ONCE ALL SLOTS ARE SECURED.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1),
              ),
            ],
          );
        },
        loading: () => const Center(child: GridLoadingIndicator(size: 40)),
        error: (e, s) => Center(child: Text('ERROR: $e')),
      ),
    );
  }

  Widget _buildActiveUI(Game game) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('TURN ${game.turnNumber} | ${game.status.value}'),
          bottom: TabBar(
            unselectedLabelColor: theme.disabledColor,
            tabs: const [
              Tab(text: 'PLAYERS'),
              Tab(text: 'REPLAY'),
              Tab(text: 'PLANNING'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Scoreboard & Status')),
            Center(child: Text('Previous Turn Replay')),
            Center(child: Text('Move Planning Grid')),
          ],
        ),
      ),
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

  Color _getFactionColor(Faction faction) {
    switch (faction) {
      case Faction.blue: return Colors.blue;
      case Faction.red: return Colors.red;
      case Faction.purple: return Colors.purple;
      case Faction.green: return Colors.green;
    }
  }
}
