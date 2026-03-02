import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:go_router/go_router.dart';

class GameBoard extends StatefulWidget {
  final String gameId;
  const GameBoard({super.key, required this.gameId});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final _supabase = Supabase.instance.client;

  Future<void> _addBot() async {
    try {
      final players = await _supabase.from('players').select('faction').eq('game_id', widget.gameId);
      final takenFactions = players.map((p) => p['faction']).toList();
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
      if (mounted) context.pop();
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

      final players = await _supabase.from('players').select('faction').eq('game_id', widget.gameId);
      final takenFactions = players.map((p) => p['faction']).toList();
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('games').stream(primaryKey: ['id']).eq('id', widget.gameId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final game = Game.fromMap(snapshot.data!.first);

        if (game.status == GameStatus.waiting) {
          return _buildWaitingUI(game);
        }

        return _buildActiveUI(game);
      },
    );
  }

  Widget _buildWaitingUI(Game game) {
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('players').stream(primaryKey: ['id']).eq('game_id', widget.gameId),
        builder: (context, snapshot) {
          final players = snapshot.data ?? [];
          final user = _supabase.auth.currentUser;
          final isJoined = players.any((p) => p['user_id'] == user?.id);
          final canJoin = players.length < game.playerCount && !isJoined;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('PLAYERS (${players.length}/${game.playerCount})'),
              ...players.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getFactionColor(p['faction']),
                    radius: 8,
                  ),
                  title: Text(p['is_bot'] ? p['bot_name'] : 'HUMAN PLAYER'),
                  subtitle: Text('FACTION: ${p['faction']}'),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => _removePlayer(p['id']),
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

  Color _getFactionColor(String faction) {
    switch (faction) {
      case 'BLUE': return Colors.blue;
      case 'RED': return Colors.red;
      case 'PURPLE': return Colors.purple;
      case 'GREEN': return Colors.green;
      default: return Colors.grey;
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
