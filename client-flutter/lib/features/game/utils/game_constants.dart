import 'package:star_cities/features/game/models/game_models.dart';

class GameConstants {
  static const int gridSize = 9;
  static const int maxTetheredShips = 5;
  static const int tetherRange = 2;
  static const int bombardRange = 2;
  static const double bombardStrength = 2.0;
  static const double supportStrengthFactor = 0.5;
  static const double bombardSupportStrength = 1.0;
  static const int maxTraySize = 5;

  static const Map<PieceType, int> visionRange = {
    PieceType.starCity: 2,
    PieceType.neutrino: 1,
    PieceType.eclipse: 2,
    PieceType.parallax: 2,
  };

  static const Map<PieceType, int> movementRange = {
    PieceType.starCity: 1,
    PieceType.neutrino: 1,
    PieceType.eclipse: 1,
    PieceType.parallax: 2,
  };

  static const Map<PieceType, int> unitStrength = {
    PieceType.starCity: 8,
    PieceType.neutrino: 2,
    PieceType.eclipse: 4,
    PieceType.parallax: 6,
  };
}
