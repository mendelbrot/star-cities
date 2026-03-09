import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';

class GameOverEventWidget extends StatelessWidget {
  final GameOverEvent event;
  final VoidCallback onDismiss;

  const GameOverEventWidget({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('GAME OVER'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.yellow, size: 64),
          const SizedBox(height: 16),
          if (event.didSomeoneWin && event.winner != null) ...[
            Text(
              '${event.winner!.name} IS VICTORIOUS!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The ${event.winner!.name} faction has secured control of the sector.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ] else ...[
            const Text(
              'NO VICTOR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            const Text('The battle for the stars continues...'),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onDismiss,
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
