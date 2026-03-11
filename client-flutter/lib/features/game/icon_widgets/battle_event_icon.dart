import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BattleEventIcon extends StatelessWidget {
  final double size;

  const BattleEventIcon({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const svgString = '''
<svg viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <g transform="rotate(32,139.69796,92.503424)" style="stroke:#000000;stroke-opacity:1;stroke-width:10">
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 96,256 H 160 l -32,-64 z" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="m 128,168 c 0,-32 0,-32 0,-32" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 80" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 128,56 V 24" />
  </g>
  <g transform="rotate(-32,116.30205,92.503418)" style="stroke:#000000;stroke-opacity:1;stroke-width:10">
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 96,256 H 160 l -32,-64 z" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="m 128,168 c 0,-32 0,-32 0,-32" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 80" />
    <path style="fill:none;stroke:#000000;stroke-width:10;stroke-linecap:round;stroke-linejoin:round" d="M 128,56 V 24" />
  </g>
  <g transform="rotate(32,139.69796,92.503424)" style="stroke:#ffffff;stroke-width:8">
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 96,256 H 160 l -32,-64 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,168 c 0,-32 0,-32 0,-32" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 80" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,56 V 24" />
  </g>
  <g transform="rotate(-32,116.30205,92.503418)" style="stroke:#ffffff;stroke-width:8">
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 96,256 H 160 l -32,-64 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,168 c 0,-32 0,-32 0,-32" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 80" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,56 V 24" />
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
