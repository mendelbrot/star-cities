import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TargetIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TargetIcon({
    super.key,
    required this.size,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final hexColor = '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
    final opacity = color.a;

    final svgString = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <!-- Outer circle -->
  <circle cx="50" cy="50" r="40" stroke="$hexColor" stroke-width="8" fill="none" stroke-opacity="$opacity" />
  <!-- Inner circle -->
  <circle cx="50" cy="50" r="10" fill="$hexColor" fill-opacity="$opacity" />
  <!-- Crosshair lines -->
  <line x1="50" y1="0" x2="50" y2="30" stroke="$hexColor" stroke-width="8" stroke-linecap="round" stroke-opacity="$opacity" />
  <line x1="50" y1="70" x2="50" y2="100" stroke="$hexColor" stroke-width="8" stroke-linecap="round" stroke-opacity="$opacity" />
  <line x1="0" y1="50" x2="30" y2="50" stroke="$hexColor" stroke-width="8" stroke-linecap="round" stroke-opacity="$opacity" />
  <line x1="70" y1="50" x2="100" y2="50" stroke="$hexColor" stroke-width="8" stroke-linecap="round" stroke-opacity="$opacity" />
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}
