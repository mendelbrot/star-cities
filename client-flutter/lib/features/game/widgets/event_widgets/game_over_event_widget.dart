import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';

class GameOverEventWidget extends StatelessWidget {
  final GameOverEvent event;
  final VoidCallback? onDismiss;

  const GameOverEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return EventCard(
      title: const Text('Game Over'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.yellow, size: 64),
          const SizedBox(height: 16),
          if (event.didSomeoneWin && event.winner != null) ...[
            Text(
              '${_capitalize(event.winner!.name)} is Victorious!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The ${_capitalize(event.winner!.name)} faction has secured control of the sector.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ] else ...[
            const Text(
              'No Victor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            const Text('The battle for the stars continues...'),
          ],
          if (onDismiss != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDismiss,
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }
}
