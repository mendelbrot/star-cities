import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';

class CityCapturedEventWidget extends StatelessWidget {
  final CityCapturedEvent event;
  final VoidCallback onDismiss;

  const CityCapturedEventWidget({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('CITY CAPTURED'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('A Star City has changed hands!', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('FROM', style: TextStyle(fontSize: 10)),
                  const SizedBox(height: 8),
                  PieceInfoRow(
                    type: PieceType.starCity,
                    faction: event.fromFaction,
                    label: event.fromFaction.name,
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
              Column(
                children: [
                  const Text('TO', style: TextStyle(fontSize: 10)),
                  const SizedBox(height: 8),
                  PieceInfoRow(
                    type: PieceType.starCity,
                    faction: event.toFaction,
                    label: event.toFaction.name,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('All ships previously tethered to this city have been lost.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
