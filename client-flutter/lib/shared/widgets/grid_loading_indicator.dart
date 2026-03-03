import 'package:flutter/material.dart';

class GridLoadingIndicator extends StatefulWidget {
  final double size;
  const GridLoadingIndicator({super.key, this.size = 40.0});

  @override
  State<GridLoadingIndicator> createState() => _GridLoadingIndicatorState();
}

class _GridLoadingIndicatorState extends State<GridLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // The order in which squares will "pulse" (spiral sequence)
  final List<int> _pulseOrder = [0, 1, 2, 5, 8, 7, 6, 3, 4];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              // Calculate opacity based on the controller value and pulse order
              final pulseIndex = _pulseOrder.indexOf(index);
              final intervalStart = pulseIndex / 9;
              final intervalEnd = (pulseIndex + 1) / 9;
              
              double opacity = 0.1;
              if (_controller.value >= intervalStart && _controller.value <= intervalEnd) {
                opacity = 1.0;
              } else if (_controller.value > intervalEnd && _controller.value < intervalEnd + 0.2) {
                // Fade out effect
                opacity = 1.0 - ((_controller.value - intervalEnd) / 0.2 * 0.9);
              }

              return Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.lerp(theme.disabledColor, theme.primaryColor, opacity)!,
                    width: 1,
                  ),
                  color: theme.primaryColor.withValues(alpha: opacity * 0.2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
