import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/features/lobby/presentation/providers/lobby_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LobbyPage extends ConsumerStatefulWidget {
  const LobbyPage({super.key});

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage> {
  final _supabase = Supabase.instance.client;
  bool _isCreating = false;

  Future<void> _createGame() async {
    setState(() => _isCreating = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final gameData = await _supabase.from('games').insert({
        'player_count': 4,
      }).select().single();

      final gameId = gameData['id'];

      await _supabase.from('players').insert({
        'game_id': gameId,
        'user_id': user.id,
        'faction': 'BLUE',
      });

      if (mounted) {
        context.push('/game/$gameId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating game: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinGame(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final existingPlayer = await _supabase
          .from('players')
          .select()
          .eq('game_id', gameId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingPlayer != null) {
        if (mounted) context.push('/game/$gameId');
        return;
      }

      final players = await _supabase.from('players').select('faction').eq('game_id', gameId);
      final takenFactions = players.map((p) => p['faction']).toList();
      final allFactions = ['BLUE', 'RED', 'PURPLE', 'GREEN'];
      final availableFaction = allFactions.firstWhere((f) => !takenFactions.contains(f));

      await _supabase.from('players').insert({
        'game_id': gameId,
        'user_id': user.id,
        'faction': availableFaction,
      });

      if (mounted) context.push('/game/$gameId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGamesAsync = ref.watch(activeGamesProvider);
    final waitingGamesAsync = ref.watch(waitingGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('STAR CITIES LOBBY'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => _supabase.auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeGamesProvider);
          ref.invalidate(waitingGamesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('YOUR ACTIVE TURNS'),
              activeGamesAsync.when(
                data: (games) => _buildGameList(games, isParticipant: true),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('WAITING FOR PLAYERS'),
              waitingGamesAsync.when(
                data: (games) => _buildGameList(games, isParticipant: false),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createGame,
        label: _isCreating ? const Text('INITIALIZING...') : const Text('CREATE NEW GAME'),
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildGameList(List<Game> games, {required bool isParticipant}) {
    if (games.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isParticipant ? 'No active games.' : 'No games waiting.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: games.map((game) => _buildGameCard(game, isParticipant: isParticipant)).toList(),
    );
  }

  Widget _buildGameCard(Game game, {required bool isParticipant}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('GAME ID: ${game.id.substring(0, 8)}'),
        subtitle: Text('STATUS: ${game.status.value} | TURN: ${game.turnNumber}'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {
          if (isParticipant || game.status == GameStatus.waiting) {
            if (isParticipant) {
              context.push('/game/${game.id}');
            } else {
              _joinGame(game.id);
            }
          }
        },
      ),
    );
  }
}
