import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';

class FactionEliminatedEventWidget extends StatelessWidget {
  final FactionEliminatedEvent event;
  final VoidCallback? onDismiss;

  const FactionEliminatedEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('FACTION ELIMINATED'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: event.faction.color, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'The ${event.faction.name} faction has been eliminated from the game.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'All remaining units of this faction have been removed from the board.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
