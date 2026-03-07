import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';

class ShipIcon extends StatefulWidget {
  final PieceType type;
  final Faction faction;
  final double size;
  final bool isAnchored;

  const ShipIcon({
    super.key,
    required this.type,
    required this.faction,
    this.size = 32,
    this.isAnchored = false,
  });

  @override
  State<ShipIcon> createState() => _ShipIconState();
}

class _ShipIconState extends State<ShipIcon> {
  static final Map<String, String> _svgCache = {};
  String? _svgString;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(ShipIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.isAnchored != widget.isAnchored) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    final path = _getAssetPath();
    if (_svgCache.containsKey(path)) {
      if (mounted) setState(() => _svgString = _svgCache[path]);
      return;
    }

    try {
      final data = await rootBundle.loadString(path);
      _svgCache[path] = data;
      if (mounted) setState(() => _svgString = data);
    } catch (e) {
      debugPrint('Error loading SVG: $e');
    }
  }

  String _getAssetPath() {
    switch (widget.type) {
      case PieceType.starCity:
        return widget.isAnchored 
          ? 'assets/ships/star-city-anchored.svg' 
          : 'assets/ships/star-city.svg';
      case PieceType.neutrino:
        return 'assets/ships/neutrino.svg';
      case PieceType.eclipse:
        return 'assets/ships/eclipse.svg';
      case PieceType.parallax:
        return 'assets/ships/parallax.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    // Replace the magenta placeholder #ff00ff with the actual faction color
    final colorHex = widget.faction.color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0');
    final tintedSvg = _svgString!.replaceAll('#ff00ff', '#$colorHex');

    return SvgPicture.string(
      tintedSvg,
      width: widget.size,
      height: widget.size,
    );
  }
}
