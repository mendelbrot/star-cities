import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/models/game_actions.dart';
import 'package:star_cities/shared/providers/robust_stream_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:star_cities/features/game/utils/vision_logic.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

/// Robust notifier for turn states.
class TurnStatesNotifier extends RobustSupabaseNotifier<TurnState, String> {
  @override
  String get tableName => 'turn_states';

  @override
  ModelFactory<TurnState> get factory => TurnState.fromMap;

  @override
  PostgrestTransformBuilder<PostgrestList> filter(PostgrestFilterBuilder<PostgrestList> query, String arg) {
    return query.eq('game_id', arg).order('turn_number', ascending: false).limit(2);
  }

  @override
  List<TurnState> postProcess(List<TurnState> data) {
    data.sort((a, b) => b.turnNumber.compareTo(a.turnNumber));
    return data.take(2).toList();
  }

  @override
  PostgresChangeFilter? getRealtimeFilter(String arg) => PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'game_id',
    value: arg,
  );

  @override
  String getId(TurnState item) => '${item.turnNumber}'; // Composite ID isn't used for deletion here, but we need something unique.
}

final robustTurnStatesProvider = AsyncNotifierProvider.autoDispose.family<TurnStatesNotifier, List<TurnState>, String>(() {
  return TurnStatesNotifier();
});

/// Manages providing the current and previous turn states.
final gameplayTurnStateProvider = Provider.autoDispose.family<AsyncValue<List<TurnState>>, String>((ref, gameId) {
  return ref.watch(robustTurnStatesProvider(gameId));
});

/// Robust notifier for turn events.
class TurnEventsNotifier extends RobustSupabaseNotifier<TurnEventList, String> {
  @override
  String get tableName => 'turn_events';

  @override
  ModelFactory<TurnEventList> get factory => TurnEventList.fromMap;

  @override
  PostgrestTransformBuilder<PostgrestList> filter(PostgrestFilterBuilder<PostgrestList> query, String arg) {
    return query.eq('game_id', arg).order('turn_number', ascending: false).limit(1);
  }

  @override
  List<TurnEventList> postProcess(List<TurnEventList> data) {
    data.sort((a, b) => b.turnNumber.compareTo(a.turnNumber));
    return data.take(1).toList();
  }

  @override
  PostgresChangeFilter? getRealtimeFilter(String arg) => PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'game_id',
    value: arg,
  );

  @override
  String getId(TurnEventList item) => '${item.turnNumber}';
}

final robustTurnEventsProvider = AsyncNotifierProvider.autoDispose.family<TurnEventsNotifier, List<TurnEventList>, String>(() {
  return TurnEventsNotifier();
});

/// Provides the most recent turn events.
final gameplayTurnEventsProvider = Provider.autoDispose.family<AsyncValue<TurnEventList?>, String>((ref, gameId) {
  final asyncValue = ref.watch(robustTurnEventsProvider(gameId));
  return asyncValue.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Fetches events for a specific turn.
final historicalTurnEventsProvider = FutureProvider.autoDispose.family<TurnEventList?, ({String gameId, int turnNumber})>((ref, arg) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('turn_events')
      .select()
      .eq('game_id', arg.gameId)
      .eq('turn_number', arg.turnNumber)
      .maybeSingle();

  if (response == null) return null;
  return TurnEventList.fromMap(response);
});

/// Fetches turn state for a specific turn.
final historicalTurnStateProvider = FutureProvider.autoDispose.family<TurnState?, ({String gameId, int turnNumber})>((ref, arg) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('turn_states')
      .select()
      .eq('game_id', arg.gameId)
      .eq('turn_number', arg.turnNumber)
      .maybeSingle();

  if (response == null) return null;
  return TurnState.fromMap(response);
});

/// Fetches vision for a specific turn.
final historicalVisionProvider = FutureProvider.autoDispose.family<Set<math.Point<int>>, ({String gameId, int turnNumber})>((ref, arg) async {
  final turnStateAsync = ref.watch(historicalTurnStateProvider(arg));
  final playersAsync = ref.watch(gamePlayersWithProfilesProvider(arg.gameId));
  final currentUser = ref.watch(currentUserProvider);

  return turnStateAsync.when(
    data: (state) => playersAsync.when(
      data: (players) {
        if (state == null) return <math.Point<int>>{};
        
        final currentPlayer = players.firstWhereOrNull(
          (p) => p.player.userId == currentUser?.id,
        ) ?? players.firstOrNull;

        if (currentPlayer == null) return <math.Point<int>>{};

        return calculateVisibleSquares(state.pieces, currentPlayer.player.faction);
      },
      loading: () => <math.Point<int>>{},
      error: (e, s) => <math.Point<int>>{},
    ),
    loading: () => <math.Point<int>>{},
    error: (e, s) => <math.Point<int>>{},
  );
});

class PendingActionsNotifier extends FamilyNotifier<List<GameAction>, String> {
  @override
  List<GameAction> build(String arg) => [];

  void addAction(GameAction action) {
    state = [...state, action];
  }

  void addOrReplaceAction(GameAction action) {
    // Replaces an existing action of the same type for the same piece
    state = [
      ...state.where((a) {
        if (a.runtimeType != action.runtimeType) return true;
        // Check piece identity based on action type
        if (a is MoveAction && action is MoveAction) return a.pieceId != action.pieceId;
        if (a is BombardAction && action is BombardAction) return a.pieceId != action.pieceId;
        if (a is TetherAction && action is TetherAction) return a.shipId != action.shipId;
        if (a is AnchorAction && action is AnchorAction) return a.pieceId != action.pieceId;
        if (a is PlaceAction && action is PlaceAction) return a.trayPieceId != action.trayPieceId;
        return true;
      }),
      action,
    ];
  }

  void removeMovementAndBombardment(String pieceId) {
    state = state.where((a) {
      if (a is MoveAction) return a.pieceId != pieceId;
      if (a is BombardAction) return a.pieceId != pieceId;
      return true;
    }).toList();
  }

  void removeBombardment(String pieceId) {
    state = state.where((a) => !(a is BombardAction && a.pieceId == pieceId)).toList();
  }

  void removePlacement(String pieceId) {
    state = state.where((a) => !(a is PlaceAction && a.trayPieceId == pieceId)).toList();
  }

  void removeTether(String pieceId) {
    state = state.where((a) => !(a is TetherAction && a.shipId == pieceId)).toList();
  }

  void removeAnchor(String pieceId) {
    state = state.where((a) => !(a is AnchorAction && a.pieceId == pieceId)).toList();
  }

  void removeAllActionsForPiece(String pieceId) {
    state = state.where((a) {
      if (a is MoveAction) return a.pieceId != pieceId;
      if (a is BombardAction) return a.pieceId != pieceId;
      if (a is TetherAction) return a.shipId != pieceId;
      if (a is AnchorAction) return a.pieceId != pieceId;
      if (a is PlaceAction) return a.trayPieceId != pieceId;
      return true;
    }).toList();
  }

  void reset() {
    state = [];
  }
}

final pendingActionsProvider = NotifierProvider.family<PendingActionsNotifier, List<GameAction>, String>(() {
  return PendingActionsNotifier();
});

/// Robust notifier for submitted turn planned actions.
class SubmittedActionsNotifier extends RobustSupabaseNotifier<SubmittedTurnActions, String> {
  @override
  String get tableName => 'turn_planned_actions';

  @override
  ModelFactory<SubmittedTurnActions> get factory => SubmittedTurnActions.fromMap;

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
  String getId(SubmittedTurnActions item) => '${item.playerId}_${item.turnNumber}';
}

final robustSubmittedActionsProvider = AsyncNotifierProvider.autoDispose.family<SubmittedActionsNotifier, List<SubmittedTurnActions>, String>(() {
  return SubmittedActionsNotifier();
});

/// Provides the submitted actions for the current user in the current game/turn.
final currentSubmittedActionsProvider = Provider.autoDispose.family<AsyncValue<SubmittedTurnActions?>, String>((ref, gameId) {
  final gameAsync = ref.watch(gameProvider(gameId));
  final playersAsync = ref.watch(playersProvider(gameId));
  final currentUser = ref.watch(currentUserProvider);
  final submittedActionsAsync = ref.watch(robustSubmittedActionsProvider(gameId));

  return gameAsync.when(
    data: (game) => playersAsync.when(
      data: (players) => submittedActionsAsync.when(
        data: (submittedList) {
          if (game == null || currentUser == null) return const AsyncValue.data(null);
          
          final currentPlayer = players.firstWhereOrNull((p) => p.userId == currentUser.id);
          if (currentPlayer == null) return const AsyncValue.data(null);

          final actions = submittedList.firstWhereOrNull(
            (a) => a.playerId == currentPlayer.id && a.turnNumber == game.turnNumber,
          );
          return AsyncValue.data(actions);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
