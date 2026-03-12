import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';

class BattleCollisionEventWidget extends StatelessWidget {
  final BattleCollisionEvent event;
  final VoidCallback? onDismiss;

  const BattleCollisionEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final String winnerText = event.result.toLowerCase() == 'capture' 
        ? '${_capitalize(event.winningFaction.name)} (Capture)'
        : _capitalize(event.winningFaction.name);

    return EventCard(
      title: const Text('Battle'),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location: (${event.coord.x}, ${event.coord.y})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (event.defendingParticipant != null) ...[
            const Text('Defending:', style: TextStyle(fontWeight: FontWeight.bold)),
            PieceInfoRow(
              type: event.defendingParticipant!.pieceType,
              faction: event.defendingParticipant!.faction,
              label: '${_capitalize(event.defendingParticipant!.faction.name)} ${event.defendingParticipant!.pieceType.name}',
            ),
            const SizedBox(height: 12),
          ],

          const Text('Entering:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: event.enteringParticipants.map((p) => PieceInfoRow(
              type: p.pieceType,
              faction: p.faction,
              label: '${_capitalize(p.faction.name)} ${p.pieceType.name}',
            )).toList(),
          ),
          const SizedBox(height: 12),

          if (event.supportingParticipants.isNotEmpty) ...[
            const Text('Support:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: event.supportingParticipants.map((p) => PieceInfoRow(
                type: p.pieceType,
                faction: p.faction,
                label: '${_capitalize(p.faction.name)} ${p.pieceType.name}',
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (event.supportingBombardments.isNotEmpty) ...[
            const Text('Bombardment Support:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: event.supportingBombardments.map((p) => PieceInfoRow(
                type: p.pieceType,
                faction: p.faction,
                label: '${_capitalize(p.faction.name)} ${p.pieceType.name}',
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],

          Divider(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24)),
          const Text('Final Strengths:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...event.calculatedStrengths.map((s) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_capitalize(s.faction.name)),
              Text(s.strength.toStringAsFixed(1)),
            ],
          )),
          const SizedBox(height: 16),
          
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text('Winner', style: TextStyle(fontSize: 10, letterSpacing: 2)),
                  Text(
                    winnerText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
