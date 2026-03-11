import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BombardActionIcon extends StatelessWidget {
  final double size;

  const BombardActionIcon({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const svgString = '''
<svg viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <g style="stroke:#000000;stroke-width:10">
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 12,128 H 96" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="m 160,128 h 84" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 128,96 V 12" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="m 128,160 v 84" />
    <circle style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="104" />
    <circle style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="64" />
  </g>
  <g style="stroke:#ffffff;stroke-width:8">
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 12,128 h 84" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 160,128 h 84" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,96 V 12" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,160 v 84" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="104" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="64" />
  </g>
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }
}
