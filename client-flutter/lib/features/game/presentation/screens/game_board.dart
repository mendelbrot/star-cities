import 'package:flutter/material.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark space background
      appBar: AppBar(
        title: const Text('Star Cities'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Stack(
                children: [
                  // Grid Lines
                  SpaceGrid(),
                  // Stars
                  StarOverlay(),
                  // Pieces
                  PieceOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Move')),
            ElevatedButton(onPressed: () {}, child: const Text('Anchor')),
            ElevatedButton(onPressed: () {}, child: const Text('Place Ship')),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class SpaceGrid extends StatelessWidget {
  const SpaceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    final step = size.width / 9;

    for (int i = 0; i <= 9; i++) {
      // Vertical lines
      canvas.drawLine(Offset(i * step, 0), Offset(i * step, size.height), paint);
      // Horizontal lines
      canvas.drawLine(Offset(0, i * step), Offset(size.width, i * step), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarOverlay extends StatelessWidget {
  const StarOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock star positions (x, y)
    final stars = [
      (1, 1), (3, 5), (6, 2), (7, 7), (2, 6), (5, 3)
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        return Stack(
          children: stars.map((pos) {
            return Positioned(
              left: pos.$1 * step + step * 0.1,
              top: pos.$2 * step + step * 0.1,
              width: step * 0.8,
              height: step * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: const RadialGradient(
                    colors: [Colors.white, Colors.yellow, Colors.orange],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class PieceOverlay extends StatelessWidget {
  const PieceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock pieces (x, y, type, color)
    final pieces = [
      (1, 1, 'Star City', Colors.blue),
      (1, 2, 'Ship', Colors.blue),
      (7, 7, 'Star City', Colors.red),
      (6, 7, 'Ship', Colors.red),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        return Stack(
          children: pieces.map((p) {
            return Positioned(
              left: p.$1 * step + step * 0.2,
              top: p.$2 * step + step * 0.2,
              width: step * 0.6,
              height: step * 0.6,
              child: p.$3 == 'Star City' 
                ? StarCityWidget(color: p.$4)
                : ShipWidget(color: p.$4),
            );
          }).toList(),
        );
      },
    );
  }
}

class StarCityWidget extends StatelessWidget {
  final Color color;
  const StarCityWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.location_city, color: Colors.white, size: 16),
      ),
    );
  }
}

class ShipWidget extends StatelessWidget {
  final Color color;
  const ShipWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShipPainter(color: color),
    );
  }
}

class ShipPainter extends CustomPainter {
  final Color color;
  ShipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
