import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/lobby/domain/models/game.dart';
import 'package:star_cities/shared/models/player.dart';
import 'package:star_cities/features/profile/domain/models/profile.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';

/// Provides a stream of a single game by its ID.
final gameProvider = StreamProvider.family<Game?, String>((ref, gameId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('games')
      .stream(primaryKey: ['id'])
      .eq('id', gameId)
      .map((data) => data.isNotEmpty ? Game.fromMap(data.first) : null);
});

/// Provides a stream of all players in a specific game.
final playersProvider = StreamProvider.family<List<Player>, String>((ref, gameId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('players')
      .stream(primaryKey: ['id'])
      .eq('game_id', gameId)
      .map((data) => data.map((m) => Player.fromMap(m)).toList());
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
final gamePlayersWithProfilesProvider = Provider.family<AsyncValue<List<PlayerWithProfile>>, String>((ref, gameId) {
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
