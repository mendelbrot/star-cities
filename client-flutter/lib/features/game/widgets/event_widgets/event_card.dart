import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final Widget title;
  final Widget content;
  final VoidCallback onDismiss;

  const EventCard({
    super.key,
    required this.title,
    required this.content,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2), // Outer border
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4), // Gap for double border
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 1), // Inner border
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.displaySmall ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    child: title,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(color: theme.colorScheme.primary, height: 24),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
