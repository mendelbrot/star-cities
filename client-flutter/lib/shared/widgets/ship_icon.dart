import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/utils/ship_svg_templates.dart';

class ShipIcon extends StatelessWidget {
  final PieceType type;
  final Faction faction;
  final double? size;
  final bool isAnchored;

  const ShipIcon({
    super.key,
    required this.type,
    required this.faction,
    this.size = 32,
    this.isAnchored = false,
  });

  @override
  Widget build(BuildContext context) {
    final svgString = getShipSvg(type, faction, isAnchored: isAnchored);

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
