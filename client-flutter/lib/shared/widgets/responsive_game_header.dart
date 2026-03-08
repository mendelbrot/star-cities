import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/features/lobby/models/game.dart';
import 'package:star_cities/shared/widgets/game_settings_chip.dart';

class ResponsiveGameHeader extends StatelessWidget {
  final Widget leading;
  final Game game;
  final bool showChevron;
  final double chipFontSize;
  final double chipIconSize;
  final bool chipsOnTop;

  const ResponsiveGameHeader({
    super.key,
    required this.leading,
    required this.game,
    this.showChevron = false,
    this.chipFontSize = 10,
    this.chipIconSize = 12,
    this.chipsOnTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Single breakpoint for stacking
        final bool shouldStack = constraints.maxWidth < 600;

        if (shouldStack) {
          final chips = _buildChipsRow(spacing: 8);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chipsOnTop) ...[
                chips,
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(child: leading),
                  if (showChevron)
                    Icon(
                      LucideIcons.chevronRight,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                ],
              ),
              if (!chipsOnTop) ...[
                const SizedBox(height: 12),
                chips,
              ],
            ],
          );
        }

        // Large Screen (Side-by-side)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading),
            const SizedBox(width: 16),
            _buildChipsRow(spacing: 8),
            if (showChevron) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _getChips() {
    final params = game.gameParameters;
    return [
      GameSettingsChip(
        icon: LucideIcons.star,
        label: '${params['star_count_to_win'] ?? 3} to win',
        fontSize: chipFontSize,
        iconSize: chipIconSize,
      ),
      GameSettingsChip(
        icon: LucideIcons.users,
        label: '${game.playerCount} players',
        fontSize: chipFontSize,
        iconSize: chipIconSize,
      ),
      GameSettingsChip(
        icon: LucideIcons.layoutGrid,
        label: '${params['grid_size'] ?? 9}x${params['grid_size'] ?? 9} grid',
        fontSize: chipFontSize,
        iconSize: chipIconSize,
      ),
    ];
  }

  Widget _buildChipsRow({double spacing = 8}) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: _getChips(),
    );
  }
}
