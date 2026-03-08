import 'package:star_cities/features/game/models/game_models.dart';
import 'package:star_cities/shared/models/faction.dart';

String getShipSvg(PieceType type, Faction faction, {bool isAnchored = false}) {
  final color = '#${faction.color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
  
  switch (type) {
    case PieceType.starCity:
      return isAnchored ? _starCityAnchored(color) : _starCity(color);
    case PieceType.neutrino:
      return _neutrino(color);
    case PieceType.eclipse:
      return _eclipse(color);
    case PieceType.parallax:
      return _parallax(color);
  }
}

String _eclipse(String color) => '''
<svg viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <g>
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="112" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="48" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="64" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="112" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="48" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="64" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="128" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="192" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="192" r="16" />
  </g>
</svg>
''';

String _neutrino(String color) => '''
<svg viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <g>
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,32 V 80" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,128 v 96" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 80,176 176,80 H 80 L 176,176" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 80,176 176,80 H 80 L 176,176" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 128,128 v 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 128,32 V 80" />
  </g>
</svg>
''';

String _parallax(String color) => '''
<svg viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <g>
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,16 V 48" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,124 80,80 H 48 Z" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="48" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="32" cy="224" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="224" cy="224" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="16" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,80 V 112" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 128,156 v 32" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="48" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="32" cy="224" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="224" cy="224" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="64" r="16" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 96,156 v 48" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 96,156 v 48" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 160,156 v 48" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 160,156 v 48" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 128,80 V 112" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 128,156 v 32" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 128,16 v 32" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 128,124 80,80 H 48 Z" />
  </g>
</svg>
''';

String _starCity(String color) => '''
<svg viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <g>
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 48,-48 48,48 -48,48 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 128,16 l 48,48 -48,48 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 48,-48 L 112,128 64,176 Z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 48,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 80,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 112,32 V 96" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 144,32 V 96" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 176,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 208,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 16,128 H 112" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 H 176" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 h 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 48,-48 48,48 -48,48 z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 128,16 l 48,48 -48,48 z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 48,-48 L 112,128 64,176 Z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 48,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 80,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 112,32 V 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 144,32 V 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 176,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 208,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 h 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 80,64 h 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 h 96" />
  </g>
</svg>
''';

String _starCityAnchored(String color) => '''
<svg viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <g>
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 48,-48 48,48 -48,48 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 128,16 l 48,48 -48,48 z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 48,-48 L 112,128 64,176 Z" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 48,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 80,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 112,32 V 96" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 144,32 V 96" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 176,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 208,96 v 64" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 16,128 H 112" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 H 176" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 h 96" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="64" cy="224" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="192" cy="224" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="224" r="16" />
    <circle style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="160" r="16" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 64,176 v 48" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="m 192,176 v 48" />
    <path style="fill:none;stroke:#ffffff;stroke-width:8;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 224" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 48,-48 48,48 -48,48 z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 80,64 128,16 l 48,48 -48,48 z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 48,-48 L 112,128 64,176 Z" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 48,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 80,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 112,32 V 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 144,32 V 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 176,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 208,96 V 160" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 16,128 h 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 80,64 h 96" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 144,128 h 96" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="64" cy="224" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="192" cy="224" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="224" r="16" />
    <circle style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" cx="128" cy="160" r="16" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 64,176 v 48" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="m 192,176 v 48" />
    <path style="fill:none;stroke:$color;stroke-width:6;stroke-linecap:round;stroke-linejoin:round" d="M 128,112 V 224" />
  </g>
</svg>
''';
