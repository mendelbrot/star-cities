import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/icon_widgets/ship_icon.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';

class PlayerRankListItem extends StatelessWidget {
  final PlayerWithProfile playerWithProfile;
  final int? starCount;

  const PlayerRankListItem({
    super.key,
    required this.playerWithProfile,
    this.starCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = playerWithProfile;

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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              p.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (p.player.isBot) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.bot,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Star count (Optional)
              if (starCount != null)
                Row(
                  children: [
                    Icon(
                      LucideIcons.star,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$starCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
