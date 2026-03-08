enum GameStatus {
  waiting('Waiting'),
  starting('Starting'),
  planning('Planning'),
  resolving('Resolving'),
  finished('Finished');

  final String value;
  const GameStatus(this.value);

  static GameStatus fromString(String status) {
    return GameStatus.values.firstWhere((e) => (e.value.toUpperCase() == status.toUpperCase()));
  }
}

class Game {
  final String id;
  final GameStatus status;
  final int turnNumber;
  final int playerCount;
  final Map<String, dynamic> gameParameters;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.status,
    required this.turnNumber,
    required this.playerCount,
    required this.gameParameters,
    required this.createdAt,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      status: GameStatus.fromString(map['status']),
      turnNumber: map['turn_number'],
      playerCount: map['player_count'],
      gameParameters: map['game_parameters'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
