import 'package:flutter/material.dart';
import 'package:star_cities/shared/icon_widgets/ship_icon.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/models/faction.dart';

class PieceInfoRow extends StatelessWidget {
  final PieceType type;
  final Faction faction;
  final String label;
  final double iconSize;

  const PieceInfoRow({
    super.key,
    required this.type,
    required this.faction,
    this.label = '',
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShipIcon(
          type: type,
          faction: faction,
          size: iconSize,
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ],
    );
  }
}
