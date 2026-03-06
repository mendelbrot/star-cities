import 'package:star_cities/shared/models/faction.dart';

class Player {
  final String id;
  final String gameId;
  final String? userId;
  final bool isBot;
  final String? botName;
  final Faction faction;
  final bool isReady;
  final bool isEliminated;
  final bool isWinner;

  Player({
    required this.id,
    required this.gameId,
    this.userId,
    required this.isBot,
    this.botName,
    required this.faction,
    required this.isReady,
    required this.isEliminated,
    required this.isWinner,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      gameId: map['game_id'],
      userId: map['user_id'],
      isBot: map['is_bot'] ?? false,
      botName: map['bot_name'],
      faction: Faction.fromString(map['faction']),
      isReady: map['is_ready'] ?? false,
      isEliminated: map['is_eliminated'] ?? false,
      isWinner: map['is_winner'] ?? false,
    );
  }

  String get displayName => isBot ? (botName ?? 'BOT') : 'HUMAN';
}
