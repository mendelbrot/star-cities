import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/utils/vision_logic.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';

/// Provides the set of visible coordinates for the current turn state of a game.
/// It returns a list of Sets: [CurrentTurnVision, PreviousTurnVision].
final visionProvider = Provider.family<AsyncValue<List<Set<math.Point<int>>>>, String>((ref, gameId) {
  final turnStatesAsync = ref.watch(gameplayTurnStateProvider(gameId));
  final playersAsync = ref.watch(gamePlayersWithProfilesProvider(gameId));
  final currentUser = ref.watch(currentUserProvider);

  return turnStatesAsync.when(
    data: (states) {
      return playersAsync.when(
        data: (players) {
          final currentPlayer = players.firstWhere(
            (p) => p.player.userId == currentUser?.id,
            orElse: () => players.first,
          );
          final faction = currentPlayer.player.faction;

          final result = states.map((s) => calculateVisibleSquares(s.pieces, faction)).toList();
          
          // Ensure we have at least two entries (even if empty) for consistency
          while (result.length < 2) {
            result.add(<math.Point<int>>{});
          }
          
          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
