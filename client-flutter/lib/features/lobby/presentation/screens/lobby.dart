import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/features/lobby/presentation/providers/lobby_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/shared/widgets/branding_header.dart';

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
    
    // Show instant loading overlay
    final overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: const Center(child: GridLoadingIndicator(size: 60)),
      ),
    );
    Overlay.of(context).insert(overlay);

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
        context.go('/game/$gameId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      overlay.remove();
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandingHeader(iconSize: 24, spacing: 4),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () => context.go('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => _supabase.auth.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userGameStatusProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildListSection('TAP Required', ref.watch(tapRequiredGamesProvider), true),
              _buildListSection('TAP Done, Waiting for Others', ref.watch(tapDoneGamesProvider), true),
              _buildListSection('Waiting for Players to Join', ref.watch(waitingForPlayersGamesProvider), true),
              _buildListSection('Open Games', ref.watch(openGamesProvider), false),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        onPressed: _isCreating ? null : _createGame,
        label: Text(_isCreating ? 'Initializing...' : 'Create New Game'),
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildListSection(String title, AsyncValue<List<Game>> asyncGames, bool isParticipant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        asyncGames.when(
          data: (games) => _buildGameList(games, isParticipant: isParticipant),
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: GridLoadingIndicator(size: 30)),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Widget _buildGameList(List<Game> games, {required bool isParticipant}) {
    if (games.isEmpty) {
      final theme = Theme.of(context);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.disabledColor, width: 1),
        ),
        child: ListTile(
          title: Text(
            'No Games',
            style: TextStyle(
              color: theme.disabledColor,
              fontSize: 12,
              letterSpacing: 1,
            ),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Game ID: ${game.id.substring(0, 8)}'),
        subtitle: Text('Status: ${game.status.value} | Turn: ${game.turnNumber}'),
        trailing: Icon(LucideIcons.chevronRight, color: Theme.of(context).primaryColor),
        onTap: () => context.go('/game/${game.id}'),
      ),
    );
  }
}
