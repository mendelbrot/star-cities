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
        return const Color(0xFFFF0000);
      case Faction.yellow:
        return const Color(0xFFFFFF00);
      case Faction.green:
        return const Color(0xFF00FF00);
      case Faction.cyan:
        return const Color(0xFF00FFFF);
      case Faction.blue:
        return const Color(0xFF0000FF);
      case Faction.magenta:
        return const Color(0xFFFF00FF);
    }
  }

  static Faction fromString(String faction) {
    return Faction.values.firstWhere((e) => e.value == faction);
  }
}
