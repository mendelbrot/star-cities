import 'package:flutter/material.dart';

class GameSettingsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final double fontSize;

  const GameSettingsChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconSize = 12,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
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
