import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/screens/game_room.dart';
import 'package:star_cities/features/game/screens/game_play.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String gameId;
  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
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
        if (game == null) {
          return const Scaffold(body: Center(child: Text('Game not found.')));
        }

        final bool isWaiting = game.status == GameStatus.waiting;

        final scaffold = Scaffold(
          appBar: _buildAppBar(game),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: isWaiting 
                    ? GameRoom(game: game) 
                    : GamePlay(game: game),
              ),
            ),
          ),
        );

        if (!isWaiting) {
          return DefaultTabController(
            length: 3,
            initialIndex: 2,
            child: scaffold,
          );
        }

        return scaffold;
      },
      loading: () => const Scaffold(
        body: Center(child: GridLoadingIndicator(size: 60)),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Game game) {
    final theme = Theme.of(context);
    final isWaiting = game.status == GameStatus.waiting;
    final title = isWaiting
        ? 'Game Room: ${game.id.substring(0, 8)}'
        : 'Turn ${game.turnNumber} | ${game.status.value}';

    return AppBar(
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.go('/'),
        tooltip: 'Back to Lobby',
      ),
      title: Text(title),
      bottom: isWaiting
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
}
