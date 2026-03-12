import 'package:flutter/material.dart';
import 'package:star_cities/features/game/models/game_events.dart';
import 'package:star_cities/features/game/widgets/event_widgets/event_card.dart';
import 'package:star_cities/features/game/widgets/event_widgets/piece_info_row.dart';

class PieceDestroyedEventWidget extends StatelessWidget {
  final GameEvent event;
  final VoidCallback? onDismiss;

  const PieceDestroyedEventWidget({
    super.key,
    required this.event,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'UNIT DESTROYED';
    String description = 'A unit has been destroyed.';
    String pieceTypeLabel = 'Unknown';
    var faction = (event is ShipDestroyedInBattleEvent) ? (event as ShipDestroyedInBattleEvent).faction : (event as ShipDestroyedInBombardmentEvent).faction;
    var pieceType = (event is ShipDestroyedInBattleEvent) ? (event as ShipDestroyedInBattleEvent).pieceType : (event as ShipDestroyedInBombardmentEvent).pieceType;

    if (event is ShipDestroyedInBattleEvent) {
      title = 'BATTLE LOSS';
      description = 'This unit was lost in combat.';
      pieceTypeLabel = pieceType.name;
    } else if (event is ShipDestroyedInBombardmentEvent) {
      title = 'BOMBARDMENT LOSS';
      description = 'This unit was destroyed by orbital fire.';
      pieceTypeLabel = pieceType.name;
    }

    return EventCard(
      title: Text(title),
      onDismiss: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Piece: ', style: TextStyle(fontWeight: FontWeight.bold)),
              PieceInfoRow(
                type: pieceType,
                faction: faction,
                label: pieceTypeLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
