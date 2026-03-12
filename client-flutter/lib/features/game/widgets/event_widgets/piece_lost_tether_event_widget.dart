import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';
import 'package:star_cities/features/game/models/game_models.dart';

class PieceLostTetherEventWidget extends StatelessWidget {
  final ShipLostTetherEvent event;
  final VoidCallback? onDismiss;

  const PieceLostTetherEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('Tether Lost'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Piece: ', style: TextStyle(fontWeight: FontWeight.bold)),
              PieceInfoRow(
                type: PieceType.starCity, // This is a limitation, ShipLostTetherEvent doesn't have PieceType
                faction: event.faction,
                label: _capitalize(event.faction.name),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This unit was lost because its Star City was captured or destroyed.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
