import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/features/game/presentation/providers/game_providers.dart';
import 'package:star_cities/shared/models/player.dart';
import 'package:go_router/go_router.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding bot: $e')));
      }
    }
  }

  Future<void> _removePlayer(String playerId) async {
    try {
      await _supabase.from('players').delete().eq('id', playerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing player: $e')));
      }
    }
  }

  Future<void> _deleteGame() async {
    try {
      await _supabase.from('games').delete().eq('id', widget.gameId);
      // Redirection is handled by ref.listen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting game: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error joining: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for game deletion
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
        if (game.status == GameStatus.waiting) return _buildWaitingUI(game);
        return _buildActiveUI(game);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildWaitingUI(Game game) {
    final playersWithProfilesAsync = ref.watch(gamePlayersWithProfilesProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(
        title: Text('GAME ROOM: ${game.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: () => _showDeleteConfirm(),
          ),
        ],
      ),
      body: playersWithProfilesAsync.when(
        data: (players) {
          final user = _supabase.auth.currentUser;
          final isJoined = players.any((p) => p.player.userId == user?.id);
          final canJoin = players.length < game.playerCount && !isJoined;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('PLAYERS (${players.length}/${game.playerCount})'),
              ...players.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getFactionColor(p.player.faction),
                    radius: 8,
                  ),
                  title: Text(p.displayName),
                  subtitle: Text('FACTION: ${p.player.faction.value}'),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => _removePlayer(p.player.id),
                  ),
                ),
              )),
              const SizedBox(height: 32),
              if (canJoin)
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
              const Text(
                'GAME WILL START AUTOMATICALLY WHEN ALL SLOTS ARE FILLED.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildActiveUI(Game game) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('TURN ${game.turnNumber} | ${game.status.value}'),
          bottom: const TabBar(
            tabs: [
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
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

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE GAME?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
