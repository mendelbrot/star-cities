import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/game/providers/gameplay_providers.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';

import 'package:star_cities/features/game/providers/gameplay_ui_state.dart';

class GameController {
  final Ref _ref;

  GameController(this._ref);

  Future<void> submitActions(String gameId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final actions = _ref.read(pendingActionsProvider(gameId));
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final playersAsync = _ref.read(playersProvider(gameId));
    final players = playersAsync.value ?? [];
    final currentPlayer = players.firstWhere((p) => p.userId == user.id);

    final gameAsync = _ref.read(gameProvider(gameId));
    final game = gameAsync.value;
    if (game == null) return;

    final actionsMap = actions.map((a) => a.toMap()).toList();

    await supabase.from('turn_planned_actions').upsert({
      'game_id': gameId,
      'turn_number': game.turnNumber,
      'player_id': currentPlayer.id,
      'actions': actionsMap,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    // Mark player as ready
    await supabase.from('players').update({'is_ready': true}).eq('id', currentPlayer.id);

    // Clear local state
    _ref.read(pendingActionsProvider(gameId).notifier).reset();
    _ref.read(gameplayUiProvider.notifier).selectPiece(null);
    _ref.read(gameplayUiProvider.notifier).resetPlacement();
  }

  Future<void> resetActions(String gameId) async {
    _ref.read(pendingActionsProvider(gameId).notifier).reset();
    _ref.read(gameplayUiProvider.notifier).selectPiece(null);
    _ref.read(gameplayUiProvider.notifier).resetPlacement();
  }


  Future<void> addBot(String gameId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final playersAsync = _ref.read(playersProvider(gameId));
    final players = playersAsync.value ?? [];
    final takenFactions = players.map((p) => p.faction).toList();
    
    final randomFaction = Faction.random(takenFactions: takenFactions);
    
    final botNames = [
      'R2-D2',
      'C-3PO',
      'HAL 9000',
      'Data',
      'TARS',
      'Skynet',
      'Deep Blue',
    ];

    final takenNames = players.map((p) => p.botName).whereType<String>().toList();
    final availableNames = botNames.where((name) => !takenNames.contains(name)).toList();

    final botName = availableNames.isEmpty 
        ? 'Vaal' 
        : availableNames[math.Random().nextInt(availableNames.length)];

    await supabase.from('players').insert({
      'game_id': gameId,
      'is_bot': true,
      'bot_name': botName,
      'faction': randomFaction.value,
    });
  }

  Future<void> removePlayer(String playerId) async {
    final supabase = _ref.read(supabaseClientProvider);
    await supabase.from('players').delete().eq('id', playerId);
  }

  Future<void> joinGame(String gameId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final playersAsync = _ref.read(playersProvider(gameId));
    final players = playersAsync.value ?? [];
    final takenFactions = players.map((p) => p.faction).toList();

    final randomFaction = Faction.random(takenFactions: takenFactions);

    await supabase.from('players').insert({
      'game_id': gameId,
      'user_id': user.id,
      'faction': randomFaction.value,
    });
  }

  Future<void> changeFaction(String playerId, Faction newFaction) async {
    final supabase = _ref.read(supabaseClientProvider);
    await supabase
        .from('players')
        .update({'faction': newFaction.value})
        .eq('id', playerId);
  }
}

final gameControllerProvider = Provider((ref) => GameController(ref));
