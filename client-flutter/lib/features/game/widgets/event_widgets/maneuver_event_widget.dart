import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';
import 'package:star_cities/features/game/models/game_models.dart';

class ManeuverEventWidget extends StatelessWidget {
  final MoveEvent event;
  final VoidCallback? onDismiss;

  const ManeuverEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('Maneuver'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary movement into an empty square.'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Piece: ', style: TextStyle(fontWeight: FontWeight.bold)),
              PieceInfoRow(
                type: PieceType.starCity, // This is a limitation, MoveEvent doesn't have PieceType
                faction: event.faction,
                label: '${event.from.x},${event.from.y} -> ${event.to.x},${event.to.y}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
