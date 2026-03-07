import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';

class BrandingHeader extends StatefulWidget {
  final double iconSize;
  final double spacing;

  const BrandingHeader({
    super.key,
    this.iconSize = 32,
    this.spacing = 8,
  });

  @override
  State<BrandingHeader> createState() => _BrandingHeaderState();
}

class _BrandingHeaderState extends State<BrandingHeader> {
  late final List<({PieceType type, Faction faction, bool isAnchored})> _icons;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _icons = List.generate(7, (_) {
      final type = PieceType.values[random.nextInt(PieceType.values.length)];
      return (
        type: type,
        faction: Faction.values[random.nextInt(Faction.values.length)],
        isAnchored: type == PieceType.starCity && random.nextBool(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: _icons.map((item) => ShipIcon(
        type: item.type,
        faction: item.faction,
        size: widget.iconSize,
        isAnchored: item.isAnchored,
      )).toList(),
    );
  }
}
