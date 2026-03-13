import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/models/player.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/shared/providers/robust_stream_provider.dart';

/// Robust notifier for all games (lobby).
class AllGamesNotifier extends RobustSupabaseNotifier<Game, String> {
  @override
  String get tableName => 'games';

  @override
  ModelFactory<Game> get factory => Game.fromMap;

  @override
  String getId(Game item) => item.id;
}

final robustAllGamesProvider = AsyncNotifierProvider.autoDispose.family<AllGamesNotifier, List<Game>, String>(() {
  return AllGamesNotifier();
});

/// Robust notifier for all players (lobby).
class AllPlayersNotifier extends RobustSupabaseNotifier<Player, String> {
  @override
  String get tableName => 'players';

  @override
  ModelFactory<Player> get factory => Player.fromMap;

  @override
  String getId(Player item) => item.id;
}

final robustAllPlayersProvider = AsyncNotifierProvider.autoDispose.family<AllPlayersNotifier, List<Player>, String>(() {
  return AllPlayersNotifier();
});

/// Combined provider that performs a client-side join of games and players.
/// This replaces the v_user_game_status view stream which doesn't support realtime updates correctly.
final userGameStatusProvider = Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  // Use empty string as arg for 'all'
  final gamesAsync = ref.watch(robustAllGamesProvider(''));
  final playersAsync = ref.watch(robustAllPlayersProvider(''));

  return gamesAsync.when(
    data: (games) => playersAsync.when(
      data: (players) {
        final result = <Map<String, dynamic>>[];
        for (var game in games) {
          final gamePlayers = players.where((p) => p.gameId == game.id).toList();
          if (gamePlayers.isEmpty) {
            result.add({
              'game_id': game.id,
              'game_status': game.status.value.toUpperCase(),
              'turn_number': game.turnNumber,
              'player_count': game.playerCount,
              'game_parameters': {
                'grid_size': game.gameParameters.gridSize,
                'star_count': game.gameParameters.starCount,
                'star_count_to_win': game.gameParameters.starCountToWin,
                'max_ships_per_city': game.gameParameters.maxShipsPerCity,
                'starting_ships': game.gameParameters.startingShips,
              },
              'stars': game.stars,
              'created_at': game.createdAt.toIso8601String(),
              'user_id': null,
              'is_ready': null,
              'faction': null,
            });
          } else {
            for (var player in gamePlayers) {
              result.add({
                'game_id': game.id,
                'game_status': game.status.value.toUpperCase(),
                'turn_number': game.turnNumber,
                'player_count': game.playerCount,
                'game_parameters': {
                  'grid_size': game.gameParameters.gridSize,
                  'star_count': game.gameParameters.starCount,
                  'star_count_to_win': game.gameParameters.starCountToWin,
                  'max_ships_per_city': game.gameParameters.maxShipsPerCity,
                  'starting_ships': game.gameParameters.startingShips,
                },
                'stars': game.stars,
                'created_at': game.createdAt.toIso8601String(),
                'user_id': player.userId,
                'is_ready': player.isReady,
                'faction': player.faction.name.toUpperCase(),
              });
            }
          }
        }
        return AsyncValue.data(result);
      },
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

/// TAP Required: Joined games, PLANNING status, is_ready == false
final tapRequiredGamesProvider = Provider.autoDispose<AsyncValue<List<Game>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);
  
  final statusAsync = ref.watch(userGameStatusProvider);

  return statusAsync.whenData((data) => data
      .where((m) => m['user_id'] == user.id && m['game_status'] == 'PLANNING' && m['is_ready'] == false)
      .map((m) => Game.fromMap({
        'id': m['game_id'],
        'status': m['game_status'],
        'turn_number': m['turn_number'],
        'created_at': m['created_at'],
        'player_count': m['player_count'],
        'game_parameters': m['game_parameters'],
        'stars': m['stars'],
      }))
      .toList());
});

/// TAP Done: Joined games, PLANNING status, is_ready == true
final tapDoneGamesProvider = Provider.autoDispose<AsyncValue<List<Game>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final statusAsync = ref.watch(userGameStatusProvider);

  return statusAsync.whenData((data) => data
      .where((m) => m['user_id'] == user.id && m['game_status'] == 'PLANNING' && m['is_ready'] == true)
      .map((m) => Game.fromMap({
        'id': m['game_id'],
        'status': m['game_status'],
        'turn_number': m['turn_number'],
        'created_at': m['created_at'],
        'player_count': m['player_count'],
        'game_parameters': m['game_parameters'],
        'stars': m['stars'],
      }))
      .toList());
});

/// Waiting for Players to Join: Games user HAS joined, status == WAITING
final waitingForPlayersGamesProvider = Provider.autoDispose<AsyncValue<List<Game>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final statusAsync = ref.watch(userGameStatusProvider);

  return statusAsync.whenData((data) => data
      .where((m) => m['user_id'] == user.id && m['game_status'] == 'WAITING')
      .map((m) => Game.fromMap({
        'id': m['game_id'],
        'status': m['game_status'],
        'turn_number': m['turn_number'],
        'created_at': m['created_at'],
        'player_count': m['player_count'],
        'game_parameters': m['game_parameters'],
        'stars': m['stars'],
      }))
      .toList());
});

/// Open Games: Games user has NOT joined, status == WAITING
final openGamesProvider = Provider.autoDispose<AsyncValue<List<Game>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final statusAsync = ref.watch(userGameStatusProvider);

  return statusAsync.whenData((data) {
    final joinedGameIds = data
        .where((m) => m['user_id'] == user.id)
        .map((m) => m['game_id'])
        .toSet();

    final uniqueGames = <String, Map<String, dynamic>>{};
    for (var m in data) {
      if (m['game_status'] == 'WAITING' && !joinedGameIds.contains(m['game_id'])) {
        uniqueGames[m['game_id']] = m;
      }
    }

    return uniqueGames.values
        .map((m) => Game.fromMap({
              'id': m['game_id'],
              'status': m['game_status'],
              'turn_number': m['turn_number'],
              'created_at': m['created_at'],
              'player_count': m['player_count'],
              'game_parameters': m['game_parameters'],
              'stars': m['stars'],
            }))
        .toList();
  });
});
