import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';

class BombardEventWidget extends StatelessWidget {
  final BombardEvent event;
  final VoidCallback onDismiss;

  const BombardEventWidget({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('BOMBARDMENT'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Target: ', style: TextStyle(fontWeight: FontWeight.bold)),
              PieceInfoRow(
                type: event.target.pieceType,
                faction: event.target.faction,
                label: '${event.target.pieceType.name} (${event.coord.x}, ${event.coord.y})',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Attacking Pieces:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: event.attackingPieces.map((p) => PieceInfoRow(
              type: p.pieceType,
              faction: p.faction,
              label: p.pieceType.name,
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attack Strength: ${event.attackStrength.toStringAsFixed(1)}'),
                  Text('Target Strength: ${event.targetStrength.toStringAsFixed(1)}'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(4),
                ),                child: Text(
                  event.isDestroyed ? 'DESTROYED' : 'SURVIVED',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
