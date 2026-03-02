import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _supabase = Supabase.instance.client;
  bool _isCreating = false;

  Future<void> _createGame() async {
    setState(() => _isCreating = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Create the game
      final gameData = await _supabase.from('games').insert({
        'player_count': 4, // Default to 4 for now
      }).select().single();

      final gameId = gameData['id'];

      // 2. Add the creator as the first player (BLUE)
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

      // Check if already in game
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

      // Find an available faction
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
    final user = _supabase.auth.currentUser;

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
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('YOUR ACTIVE TURNS'),
              _buildActiveGames(user?.id),
              const SizedBox(height: 32),
              _buildSectionTitle('WAITING FOR PLAYERS'),
              _buildWaitingGames(),
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

  Widget _buildActiveGames(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('players')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final playerRecords = snapshot.data!;
        if (playerRecords.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No active games.', textAlign: TextAlign.center),
            ),
          );
        }

        final gameIds = playerRecords.map((p) => p['game_id'] as String).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase
              .from('games')
              .select()
              .inFilter('id', gameIds)
              .neq('status', 'FINISHED')
              .order('updated_at', ascending: false),
          builder: (context, gameSnapshot) {
            if (!gameSnapshot.hasData) return const SizedBox.shrink();
            final games = gameSnapshot.data!.map((m) => Game.fromMap(m)).toList();

            return Column(
              children: games.map((game) => _buildGameCard(game, isParticipant: true)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildWaitingGames() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('games')
          .stream(primaryKey: ['id'])
          .eq('status', 'WAITING')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final games = snapshot.data!.map((m) => Game.fromMap(m)).toList();

        if (games.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No games waiting.', textAlign: TextAlign.center),
            ),
          );
        }

        return Column(
          children: games.map((game) => _buildGameCard(game)).toList(),
        );
      },
    );
  }

  Widget _buildGameCard(Game game, {bool isParticipant = false}) {
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
