import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BattleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BattleIcon({
    super.key,
    required this.size,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    // Using a simpler approach as requested
    const hexColor = '#FF9800'; // Orange
    const opacity = 1.0;

    const svgString = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <!-- Lightning bolt / Explosion combo -->
  <path d="M50 5 L30 50 L50 50 L40 95 L80 40 L55 40 L65 5 Z" fill="$hexColor" fill-opacity="$opacity" stroke="white" stroke-width="2" />
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}
