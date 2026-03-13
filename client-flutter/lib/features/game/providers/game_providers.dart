import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/models/player.dart';
import 'package:star_cities/features/profile/models/profile.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/shared/providers/robust_stream_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Robust notifier for a single game.
class GameNotifier extends RobustSupabaseNotifier<Game, String> {
  @override
  String get tableName => 'games';

  @override
  ModelFactory<Game> get factory => Game.fromMap;

  @override
  PostgrestTransformBuilder<PostgrestList> filter(PostgrestFilterBuilder<PostgrestList> query, String arg) {
    return query.eq('id', arg);
  }

  @override
  PostgresChangeFilter? getRealtimeFilter(String arg) => PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'id',
    value: arg,
  );

  @override
  String getId(Game item) => item.id;
}

final robustGameProvider = AsyncNotifierProvider.autoDispose.family<GameNotifier, List<Game>, String>(() {
  return GameNotifier();
});

/// Provides a stream of a single game by its ID.
final gameProvider = Provider.autoDispose.family<AsyncValue<Game?>, String>((ref, gameId) {
  final asyncValue = ref.watch(robustGameProvider(gameId));
  return asyncValue.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Robust notifier for players in a game.
class PlayersNotifier extends RobustSupabaseNotifier<Player, String> {
  @override
  String get tableName => 'players';

  @override
  ModelFactory<Player> get factory => Player.fromMap;

  @override
  PostgrestTransformBuilder<PostgrestList> filter(PostgrestFilterBuilder<PostgrestList> query, String arg) {
    return query.eq('game_id', arg);
  }

  @override
  PostgresChangeFilter? getRealtimeFilter(String arg) => PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'game_id',
    value: arg,
  );

  @override
  String getId(Player item) => item.id;
}

final robustPlayersProvider = AsyncNotifierProvider.autoDispose.family<PlayersNotifier, List<Player>, String>(() {
  return PlayersNotifier();
});

/// Provides a stream of all players in a specific game.
final playersProvider = Provider.autoDispose.family<AsyncValue<List<Player>>, String>((ref, gameId) {
  return ref.watch(robustPlayersProvider(gameId));
});

/// Provides a stream of all user profiles.
final allProfilesProvider = StreamProvider<Map<String, Profile>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('user_profiles')
      .stream(primaryKey: ['id'])
      .map((data) => {
        for (var m in data) m['id'] as String: Profile.fromMap(m)
      });
});

/// Represents a Player combined with their Profile data.
class PlayerWithProfile {
  final Player player;
  final Profile? profile;
  PlayerWithProfile(this.player, this.profile);

  String get displayName => player.isBot ? (player.botName ?? 'BOT') : (profile?.username ?? 'HUMAN');
}

/// Provides a combined list of players and their profiles for a specific game.
final gamePlayersWithProfilesProvider = Provider.autoDispose.family<AsyncValue<List<PlayerWithProfile>>, String>((ref, gameId) {
  final playersAsync = ref.watch(playersProvider(gameId));
  final profilesAsync = ref.watch(allProfilesProvider);

  return playersAsync.when(
    data: (players) => profilesAsync.when(
      data: (profiles) => AsyncValue.data(
        players.map((p) => PlayerWithProfile(p, profiles[p.userId])).toList(),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
