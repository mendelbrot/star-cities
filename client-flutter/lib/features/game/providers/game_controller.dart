import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/providers/auth_providers.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';

class GameController {
  final Ref _ref;

  GameController(this._ref);

  Future<void> addBot(String gameId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final playersAsync = _ref.read(playersProvider(gameId));
    final players = playersAsync.value ?? [];
    final takenFactions = players.map((p) => p.faction).toList();
    final availableFactions = Faction.values.where((f) => !takenFactions.contains(f)).toList();
    
    if (availableFactions.isEmpty) return;
    
    final randomFaction = availableFactions[math.Random().nextInt(availableFactions.length)];
    
    final botNames = [
      'R2-D2',
      'C-3PO',
      'HAL 9000',
      'Data',
      'TARS',
      'Skynet',
      'Deep Blue',
    ];
    final randomName = botNames[math.Random().nextInt(botNames.length)];

    await supabase.from('players').insert({
      'game_id': gameId,
      'is_bot': true,
      'bot_name': randomName,
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
    final availableFactions = Faction.values.where((f) => !takenFactions.contains(f)).toList();

    if (availableFactions.isEmpty) return;
    
    final randomFaction = availableFactions[math.Random().nextInt(availableFactions.length)];

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
