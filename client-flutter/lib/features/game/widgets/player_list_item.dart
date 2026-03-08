import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/widgets/ship_icon.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/features/game/providers/game_controller.dart';

class PlayerListItem extends ConsumerWidget {
  final PlayerWithProfile playerWithProfile;
  final List<Faction> availableFactions;
  final bool isCurrentPlayer;

  const PlayerListItem({
    super.key,
    required this.playerWithProfile,
    required this.availableFactions,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = playerWithProfile;
    final controller = ref.read(gameControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // Left: Ship icon and name
              Expanded(
                child: Row(
                  children: [
                    ShipIcon(
                      type: PieceType.starCity,
                      faction: p.player.faction,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Center/Right: Faction color selector and Remove button
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<Faction>(
                      enabled: isCurrentPlayer || p.player.isBot,
                      onSelected: (faction) => controller.changeFaction(p.player.id, faction),
                      itemBuilder: (context) => availableFactions.map((f) => PopupMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: f.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(f.value),
                          ],
                        ),
                      )).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.disabledColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Faction: ${p.player.faction.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCurrentPlayer || p.player.isBot 
                                ? theme.primaryColor 
                                : theme.disabledColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Right: X or placeholder
                    p.player.isBot 
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => controller.removePlayer(p.player.id),
                          tooltip: 'Remove Bot',
                        )
                      : const IconButton(
                          icon: Opacity(
                            opacity: 0,
                            child: Icon(LucideIcons.x, size: 20),
                          ),
                          onPressed: null,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
