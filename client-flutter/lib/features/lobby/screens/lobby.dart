import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/features/lobby/providers/lobby_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';
import 'package:star_cities/shared/widgets/responsive_game_header.dart';

class Lobby extends ConsumerStatefulWidget {
  const Lobby({super.key});

  @override
  ConsumerState<Lobby> createState() => _LobbyState();
}

class _LobbyState extends ConsumerState<Lobby> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Star Cities', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userGameStatusProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildListSection(
                      'TAP Required',
                      ref.watch(tapRequiredGamesProvider),
                      true,
                    ),
                    _buildListSection(
                      'TAP Done, Waiting for Others',
                      ref.watch(tapDoneGamesProvider),
                      true,
                    ),
                    _buildListSection(
                      'Waiting for Players to Join',
                      ref.watch(waitingForPlayersGamesProvider),
                      true,
                    ),
                    _buildListSection(
                      'Open Games',
                      ref.watch(openGamesProvider),
                      false,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
        ),
        onPressed: () => context.push('/game-setup'),
        label: const Text('Create New Game'),
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildListSection(
    String title,
    AsyncValue<List<Game>> asyncGames,
    bool isParticipant,
  ) {
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
            child: Text(
              'Error: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.secondary,
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
      children: games
          .map((game) => _buildGameCard(game, isParticipant: isParticipant))
          .toList(),
    );
  }

  Widget _buildGameCard(Game game, {required bool isParticipant}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/game/${game.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ResponsiveGameHeader(
            game: game,
            showChevron: true,
            chipFontSize: 8,
            chipIconSize: 10,
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game ID: ${game.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status:\u00A0${game.status.value}  |  Turn:\u00A0${game.turnNumber}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
