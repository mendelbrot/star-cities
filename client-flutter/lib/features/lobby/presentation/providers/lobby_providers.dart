import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';

final _supabase = Supabase.instance.client;

/// Provides the list of games currently waiting for players.
final waitingGamesProvider = StreamProvider<List<Game>>((ref) {
  return _supabase
      .from('games')
      .stream(primaryKey: ['id'])
      .eq('status', 'WAITING')
      .order('created_at', ascending: false)
      .map((data) => data.map((m) => Game.fromMap(m)).toList());
});

/// Provides the IDs of games the current user has joined.
final userGameIdsProvider = StreamProvider<List<String>>((ref) {
  final user = _supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return _supabase
      .from('players')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) => data.map((m) => m['game_id'] as String).toList());
});

/// Provides the list of active games for the current user.
final activeGamesProvider = StreamProvider<List<Game>>((ref) {
  final gameIdsAsync = ref.watch(userGameIdsProvider);

  return gameIdsAsync.when(
    data: (ids) {
      if (ids.isEmpty) return Stream.value([]);
      
      return _supabase
          .from('games')
          .stream(primaryKey: ['id'])
          .order('updated_at', ascending: false)
          .map((data) => data
              .where((m) => ids.contains(m['id']) && m['status'] != 'FINISHED')
              .map((m) => Game.fromMap(m))
              .toList());
    },
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});
