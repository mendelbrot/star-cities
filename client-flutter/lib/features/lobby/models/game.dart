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

class GameParameters {
  final int gridSize;
  final int starCount;
  final int starCountToWin;
  final int maxShipsPerCity;
  final List<String> startingShips;

  GameParameters({
    this.gridSize = 9,
    this.starCount = 6,
    this.starCountToWin = 3,
    this.maxShipsPerCity = 5,
    this.startingShips = const ["NEUTRINO", "NEUTRINO", "PARALLAX", "ECLIPSE"],
  });

  factory GameParameters.fromMap(Map<String, dynamic> map) {
    return GameParameters(
      gridSize: map['grid_size'] ?? 9,
      starCount: map['star_count'] ?? 6,
      starCountToWin: map['star_count_to_win'] ?? 3,
      maxShipsPerCity: map['max_ships_per_city'] ?? 5,
      startingShips: List<String>.from(map['starting_ships'] ?? []),
    );
  }
}

class Game {
  final String id;
  final GameStatus status;
  final int turnNumber;
  final int playerCount;
  final List<Map<String, int>> stars;
  final GameParameters gameParameters;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.status,
    required this.turnNumber,
    required this.playerCount,
    required this.stars,
    required this.gameParameters,
    required this.createdAt,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      status: GameStatus.fromString(map['status']),
      turnNumber: map['turn_number'],
      playerCount: map['player_count'],
      stars: (map['stars'] as List? ?? [])
          .map((s) => Map<String, int>.from(s))
          .toList(),
      gameParameters: GameParameters.fromMap(map['game_parameters'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
