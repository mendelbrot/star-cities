enum GameStatus {
  waiting('WAITING'),
  starting('STARTING'),
  planning('PLANNING'),
  resolving('RESOLVING'),
  finished('FINISHED');

  final String value;
  const GameStatus(this.value);

  static GameStatus fromString(String status) {
    return GameStatus.values.firstWhere((e) => e.value == status);
  }
}

class Game {
  final String id;
  final GameStatus status;
  final int turnNumber;
  final int playerCount;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.status,
    required this.turnNumber,
    required this.playerCount,
    required this.createdAt,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      status: GameStatus.fromString(map['status']),
      turnNumber: map['turn_number'],
      playerCount: map['player_count'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
