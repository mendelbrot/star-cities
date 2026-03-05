import 'package:flutter/material.dart';

enum Faction {
  red('RED'),
  yellow('YELLOW'),
  green('GREEN'),
  cyan('CYAN'),
  blue('BLUE'),
  magenta('MAGENTA');

  final String value;
  const Faction(this.value);

  Color get color {
    switch (this) {
      case Faction.red:
        return Colors.red;
      case Faction.yellow:
        return Colors.yellow;
      case Faction.green:
        return Colors.green;
      case Faction.cyan:
        return Colors.cyan;
      case Faction.blue:
        return Colors.indigo;
      case Faction.magenta:
        return const Color(0xFFFF00FF);
    }
  }

  static Faction fromString(String faction) {
    return Faction.values.firstWhere((e) => e.value == faction);
  }
}

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
