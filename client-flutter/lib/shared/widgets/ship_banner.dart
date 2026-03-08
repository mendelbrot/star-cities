import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';

class ShipBanner extends StatelessWidget {
  final int shipCount;
  final double spacing;

  const ShipBanner({
    super.key,
    this.shipCount = 9,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (shipCount - 1);
        final iconSize = (constraints.maxWidth - totalSpacing) / shipCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            shipCount,
            (_) => SizedBox(
              width: iconSize,
              height: iconSize,
              child: const RandomShip(),
            ),
          ),
        );
      },
    );
  }
}

class RandomShip extends StatefulWidget {
  const RandomShip({super.key});

  @override
  State<RandomShip> createState() => _RandomShipState();
}

class _RandomShipState extends State<RandomShip> {
  late PieceType _type;
  late Faction _faction;
  late bool _isAnchored;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _randomize();
  }

  void _randomize() {
    setState(() {
      _type = PieceType.values[_random.nextInt(PieceType.values.length)];
      _faction = Faction.values[_random.nextInt(Faction.values.length)];
      _isAnchored = _type == PieceType.starCity && _random.nextBool();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _randomize,
      behavior: HitTestBehavior.opaque,
      child: ShipIcon(
        type: _type,
        faction: _faction,
        isAnchored: _isAnchored,
        size: null, // Fill the parent SizedBox
      ),
    );
  }
}
