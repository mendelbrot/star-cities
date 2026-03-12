import 'package:flutter/material.dart';
import 'package:star_cities/features/game/providers/game_providers.dart';
import 'package:star_cities/shared/icon_widgets/ship_icon.dart';
import 'package:star_cities/features/game/models/game_models.dart';

class GameOver extends StatelessWidget {
  final PlayerWithProfile? winner;

  const GameOver({super.key, this.winner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Game Over',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          if (winner == null)
            Text(
              'Draw',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            ShipIcon(
              type: PieceType.starCity,
              faction: winner!.player.faction,
              size: 128,
              isAnchored: true,
            ),
            const SizedBox(height: 32),
            Text(
              'Winner: ${winner!.displayName}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
