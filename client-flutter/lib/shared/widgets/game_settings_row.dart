import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/models/game.dart';

class GameSettingsRow extends StatelessWidget {
  final Game game;
  final double iconSize;
  final double fontSize;
  final WrapAlignment alignment;

  const GameSettingsRow({
    super.key,
    required this.game,
    this.iconSize = 12,
    this.fontSize = 10,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final params = game.gameParameters;
    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          context,
          LucideIcons.star,
          '${params['star_count_to_win'] ?? 3} to win',
        ),
        _buildInfoChip(
          context,
          LucideIcons.users,
          '${game.playerCount} players',
        ),
        _buildInfoChip(
          context,
          LucideIcons.layoutGrid,
          '${params['grid_size'] ?? 9}x${params['grid_size'] ?? 9} grid',
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: fontSize,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
