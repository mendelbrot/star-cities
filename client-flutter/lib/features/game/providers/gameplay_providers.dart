import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';

/// Manages fetching the current and previous turn states via REST.
/// Only re-fetches when the game enters the PLANNING status.
class TurnStateNotifier extends FamilyAsyncNotifier<List<TurnState>, String> {
  @override
  Future<List<TurnState>> build(String arg) async {
    final gameId = arg;
    // Watch status and turn number
    final game = ref.watch(gameProvider(gameId)).value;
    
    // We only trigger fetch if in PLANNING mode
    if (game?.status == GameStatus.planning) {
      return _fetch(gameId);
    }
    
    // If we're loading or in other states, return what we have or empty
    return state.value ?? [];
  }

  Future<List<TurnState>> _fetch(String gameId) async {
    final supabase = ref.read(supabaseClientProvider);
    
    final response = await supabase
        .from('turn_states')
        .select()
        .eq('game_id', gameId)
        .order('turn_number', ascending: false)
        .limit(2);

    final List<dynamic> data = response;
    return data.map((m) => TurnState.fromMap(m)).toList();
  }
}

final gameplayTurnStateProvider = AsyncNotifierProvider.family<TurnStateNotifier, List<TurnState>, String>(() {
  return TurnStateNotifier();
});

/// Manages fetching the most recent turn events via REST.
/// Only re-fetches when the game enters the PLANNING status.
class TurnEventsNotifier extends FamilyAsyncNotifier<TurnEventList?, String> {
  @override
  Future<TurnEventList?> build(String arg) async {
    final gameId = arg;
    final game = ref.watch(gameProvider(gameId)).value;

    if (game?.status == GameStatus.planning) {
      return _fetch(gameId);
    }

    return state.value;
  }

  Future<TurnEventList?> _fetch(String gameId) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase
        .from('turn_events')
        .select()
        .eq('game_id', gameId)
        .order('turn_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return TurnEventList.fromMap(response);
  }
}

final gameplayTurnEventsProvider = AsyncNotifierProvider.family<TurnEventsNotifier, TurnEventList?, String>(() {
  return TurnEventsNotifier();
});
