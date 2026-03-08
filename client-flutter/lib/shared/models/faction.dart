import 'dart:math' as math;
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

  static Faction random({List<Faction> takenFactions = const []}) {
    final available = Faction.values.where((f) => !takenFactions.contains(f)).toList();
    if (available.isEmpty) return Faction.blue; // Fallback
    return available[math.Random().nextInt(available.length)];
  }
}
