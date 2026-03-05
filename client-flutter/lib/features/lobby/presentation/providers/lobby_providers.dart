import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';

/// Base stream for the games table.
final gamesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.from('games').stream(primaryKey: ['id']);
});

/// Base stream for the players table.
final playersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.from('players').stream(primaryKey: ['id']);
});

/// Combined provider that performs a client-side join of games and players.
/// This replaces the v_user_game_status view stream which doesn't support realtime updates correctly.
final userGameStatusProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final gamesAsync = ref.watch(gamesStreamProvider);
  final playersAsync = ref.watch(playersStreamProvider);

  return gamesAsync.when(
    data: (games) => playersAsync.when(
      data: (players) {
        final result = <Map<String, dynamic>>[];
        for (var game in games) {
          final gamePlayers = players.where((p) => p['game_id'] == game['id']).toList();
          if (gamePlayers.isEmpty) {
            result.add({
              'game_id': game['id'],
              'game_status': game['status'],
              'turn_number': game['turn_number'],
              'player_count': game['player_count'],
              'created_at': game['created_at'],
              'user_id': null,
              'is_ready': null,
              'faction': null,
            });
          } else {
            for (var player in gamePlayers) {
              result.add({
                'game_id': game['id'],
                'game_status': game['status'],
                'turn_number': game['turn_number'],
                'player_count': game['player_count'],
                'created_at': game['created_at'],
                'user_id': player['user_id'],
                'is_ready': player['is_ready'],
                'faction': player['faction'],
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
final tapRequiredGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
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
      }))
      .toList());
});

/// TAP Done: Joined games, PLANNING status, is_ready == true
final tapDoneGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
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
      }))
      .toList());
});

/// Waiting for Players to Join: Games user HAS joined, status == WAITING
final waitingForPlayersGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
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
      }))
      .toList());
});

/// Open Games: Games user has NOT joined, status == WAITING
final openGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
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
            }))
        .toList();
  });
});
