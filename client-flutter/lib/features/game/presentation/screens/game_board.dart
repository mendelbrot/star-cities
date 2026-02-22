import 'package:flutter/material.dart';
import 'dart:math' as math;

class Piece {
  final String id;
  final int x;
  final int y;
  final String type;
  final Color color;

  Piece({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.color,
  });

  Piece copyWith({int? x, int? y}) {
    return Piece(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type,
      color: color,
    );
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final List<Piece> _pieces = [
    Piece(id: '1', x: 1, y: 1, type: 'Star City', color: Colors.blue),
    Piece(id: '2', x: 1, y: 2, type: 'Ship', color: Colors.blue),
    Piece(id: '3', x: 7, y: 7, type: 'Star City', color: Colors.red),
    Piece(id: '4', x: 6, y: 7, type: 'Ship', color: Colors.red),
  ];

  final List<Piece> _trayPieces = [
    Piece(id: 't1', x: 0, y: 0, type: 'Ship', color: Colors.blue),
    Piece(id: 't2', x: 1, y: 0, type: 'Ship', color: Colors.blue),
    Piece(id: 't3', x: 2, y: 0, type: 'Star City', color: Colors.blue),
  ];

  String? _selectedPieceId;
  bool _isSelectedFromTray = false;
  final Map<String, math.Point<int>> _plannedMoves = {};

  void _onSquareTapped(int x, int y) {
    setState(() {
      final tappedPiece = _pieces.where((p) => p.x == x && p.y == y).firstOrNull;

      if (_selectedPieceId == null) {
        if (tappedPiece != null) {
          _selectedPieceId = tappedPiece.id;
          _isSelectedFromTray = false;
        }
      } else {
        if (_isSelectedFromTray) {
          // Check if tapped square is valid for placement
          if (_isValidPlacementSquare(x, y)) {
            _plannedMoves[_selectedPieceId!] = math.Point(x, y);
            _selectedPieceId = null;
          } else {
            // Illegal square, cancel placement selection
            _selectedPieceId = null;
          }
        } else {
          // Board piece move logic
          final selectedPiece = _pieces.firstWhere((p) => p.id == _selectedPieceId);

          if (tappedPiece != null && tappedPiece.id == _selectedPieceId) {
            if (_plannedMoves.containsKey(_selectedPieceId)) {
              _plannedMoves.remove(_selectedPieceId);
            } else {
              _selectedPieceId = null;
            }
          } else if (tappedPiece != null) {
            _selectedPieceId = tappedPiece.id;
            _isSelectedFromTray = false;
          } else {
            if (_isWithinDistance(selectedPiece.x, selectedPiece.y, x, y, 2)) {
              _plannedMoves[_selectedPieceId!] = math.Point(x, y);
              _selectedPieceId = null;
            } else {
              _selectedPieceId = null;
            }
          }
        }
      }
    });
  }

  void _onTraySquareTapped(int index) {
    setState(() {
      final tappedPiece = _trayPieces.where((p) => p.x == index).firstOrNull;
      if (tappedPiece == null) {
        _selectedPieceId = null;
        return;
      }

      if (_plannedMoves.containsKey(tappedPiece.id)) {
        // Clicking a greyed out piece removes the placement and selects it
        _plannedMoves.remove(tappedPiece.id);
        _selectedPieceId = tappedPiece.id;
        _isSelectedFromTray = true;
      } else if (_selectedPieceId == tappedPiece.id) {
        // Toggle selection off if no placement exists
        _selectedPieceId = null;
      } else {
        _selectedPieceId = tappedPiece.id;
        _isSelectedFromTray = true;
      }
    });
  }

  bool _isValidPlacementSquare(int x, int y) {
    // Square must be empty (no piece and no other planned move/placement)
    final isOccupiedByPiece = _pieces.any((p) => p.x == x && p.y == y);
    final isOccupiedByPlan = _plannedMoves.values.any((p) => p.x == x && p.y == y);
    if (isOccupiedByPiece || isOccupiedByPlan) return false;

    // Must be distance 1 from a blue star city
    final blueStarCities = _pieces.where((p) => p.type == 'Star City' && p.color == Colors.blue);
    for (final city in blueStarCities) {
      if (_isWithinDistance(city.x, city.y, x, y, 1)) {
        return true;
      }
    }
    return false;
  }

  bool _isWithinDistance(int x1, int y1, int x2, int y2, int distance) {
    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();
    dx = math.min(dx, 9 - dx);
    dy = math.min(dy, 9 - dy);
    return math.max(dx, dy) <= distance && math.max(dx, dy) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Star Cities'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Game Board
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final step = constraints.maxWidth / 9;
                  return GestureDetector(
                    onTapUp: (details) {
                      final x = details.localPosition.dx ~/ step;
                      final y = details.localPosition.dy ~/ step;
                      if (x >= 0 && x < 9 && y >= 0 && y < 9) {
                        _onSquareTapped(x, y);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const SpaceGrid(),
                          const StarOverlay(),
                          if (_selectedPieceId != null)
                            ValidMoveMarkers(
                              selectedPiece: _isSelectedFromTray 
                                ? _trayPieces.firstWhere((p) => p.id == _selectedPieceId)
                                : _pieces.firstWhere((p) => p.id == _selectedPieceId),
                              isSelectedFromTray: _isSelectedFromTray,
                              pieces: _pieces,
                              plannedMoves: _plannedMoves,
                            ),
                          PlannedMoveArrows(
                            pieces: _pieces,
                            plannedMoves: _plannedMoves,
                          ),
                          PieceOverlay(
                            pieces: _pieces,
                            selectedPieceId: _isSelectedFromTray ? null : _selectedPieceId,
                            plannedMoves: _plannedMoves,
                          ),
                          // Ghost pieces for planned placements
                          PlannedPlacementOverlay(
                            trayPieces: _trayPieces,
                            plannedMoves: _plannedMoves,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AspectRatio(
              aspectRatio: 9 / 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final step = constraints.maxWidth / 9;
                  return GestureDetector(
                    onTapUp: (details) {
                      final x = details.localPosition.dx ~/ step;
                      if (x >= 0 && x < 9) {
                        _onTraySquareTapped(x);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const SpaceGrid(rows: 1, cols: 9),
                          PieceOverlay(
                            pieces: _trayPieces,
                            selectedPieceId: _isSelectedFromTray ? _selectedPieceId : null,
                            rows: 1,
                            plannedMoves: _plannedMoves,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
              onPressed: () {
                setState(() {
                  _plannedMoves.clear();
                  _selectedPieceId = null;
                  _isSelectedFromTray = false;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
              child: const Text('Reset'),
            ),
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
  final int rows;
  final int cols;
  const SpaceGrid({super.key, this.rows = 9, this.cols = 9});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(rows: rows, cols: cols),
    );
  }
}

class GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  GridPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    final stepX = size.width / cols;
    final stepY = size.height / rows;

    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(Offset(i * stepX, 0), Offset(i * stepX, size.height), paint);
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(Offset(0, i * stepY), Offset(size.width, i * stepY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarOverlay extends StatelessWidget {
  const StarOverlay({super.key});

  @override
  Widget build(BuildContext context) {
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
  final List<Piece> pieces;
  final String? selectedPieceId;
  final int rows;
  final int cols;
  final Map<String, math.Point<int>> plannedMoves;

  const PieceOverlay({
    super.key,
    required this.pieces,
    this.selectedPieceId,
    this.rows = 9,
    this.cols = 9,
    required this.plannedMoves,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stepX = constraints.maxWidth / cols;
        final stepY = constraints.maxHeight / rows;
        return Stack(
          children: [
            ...pieces.map((p) {
              final isSelected = p.id == selectedPieceId;
              final hasPlan = plannedMoves.containsKey(p.id);
              return Positioned(
                left: p.x * stepX,
                top: p.y * stepY,
                width: stepX,
                height: stepY,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: hasPlan ? 0.3 : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(stepX * 0.2),
                      decoration: isSelected ? BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.1),
                      ) : null,
                      child: p.type == 'Star City' 
                        ? StarCityWidget(color: p.color)
                        : ShipWidget(color: p.color),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class PlannedPlacementOverlay extends StatelessWidget {
  final List<Piece> trayPieces;
  final Map<String, math.Point<int>> plannedMoves;

  const PlannedPlacementOverlay({
    super.key,
    required this.trayPieces,
    required this.plannedMoves,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        final widgets = <Widget>[];

        plannedMoves.forEach((pieceId, target) {
          final trayPiece = trayPieces.where((p) => p.id == pieceId).firstOrNull;
          if (trayPiece != null) {
            widgets.add(
              Positioned(
                left: target.x * step,
                top: target.y * step,
                width: step,
                height: step,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    padding: EdgeInsets.all(step * 0.2),
                    child: trayPiece.type == 'Star City' 
                      ? StarCityWidget(color: trayPiece.color)
                      : ShipWidget(color: trayPiece.color),
                  ),
                ),
              ),
            );
          }
        });

        return Stack(children: widgets);
      },
    );
  }
}

class ValidMoveMarkers extends StatelessWidget {
  final Piece selectedPiece;
  final bool isSelectedFromTray;
  final List<Piece> pieces;
  final Map<String, math.Point<int>> plannedMoves;

  const ValidMoveMarkers({
    super.key,
    required this.selectedPiece,
    required this.isSelectedFromTray,
    required this.pieces,
    required this.plannedMoves,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        List<Widget> markers = [];

        if (isSelectedFromTray) {
          // Placement markers: distance 1 from blue star cities
          final blueStarCities = pieces.where((p) => p.type == 'Star City' && p.color == Colors.blue);
          final Set<math.Point<int>> validPoints = {};

          for (final city in blueStarCities) {
            for (int dx = -1; dx <= 1; dx++) {
              for (int dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) continue;
                int tx = (city.x + dx) % 9;
                int ty = (city.y + dy) % 9;
                if (tx < 0) tx += 9;
                if (ty < 0) ty += 9;

                // Check if occupied
                final isOccupiedByPiece = pieces.any((p) => p.x == tx && p.y == ty);
                final isOccupiedByPlan = plannedMoves.values.any((p) => p.x == tx && p.y == ty);
                
                if (!isOccupiedByPiece && !isOccupiedByPlan) {
                  validPoints.add(math.Point(tx, ty));
                }
              }
            }
          }

          for (final pt in validPoints) {
            markers.add(_buildMarker(pt.x, pt.y, step));
          }
        } else {
          // Regular move markers: distance 2 from piece
          for (int dx = -2; dx <= 2; dx++) {
            for (int dy = -2; dy <= 2; dy++) {
              if (dx == 0 && dy == 0) continue;
              int tx = (selectedPiece.x + dx) % 9;
              int ty = (selectedPiece.y + dy) % 9;
              if (tx < 0) tx += 9;
              if (ty < 0) ty += 9;
              markers.add(_buildMarker(tx, ty, step));
            }
          }
        }

        return Stack(children: markers);
      },
    );
  }

  Widget _buildMarker(int x, int y, double step) {
    return Positioned(
      left: x * step,
      top: y * step,
      width: step,
      height: step,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: step * 0.3,
            height: step * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class PlannedMoveArrows extends StatelessWidget {
  final List<Piece> pieces;
  final Map<String, math.Point<int>> plannedMoves;

  const PlannedMoveArrows({
    super.key,
    required this.pieces,
    required this.plannedMoves,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: ArrowPainter(
        pieces: pieces,
        plannedMoves: plannedMoves,
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final List<Piece> pieces;
  final Map<String, math.Point<int>> plannedMoves;

  ArrowPainter({required this.pieces, required this.plannedMoves});

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    plannedMoves.forEach((pieceId, target) {
      final piece = pieces.where((p) => p.id == pieceId).firstOrNull;
      if (piece == null) return;
      
      final start = Offset((piece.x + 0.5) * step, (piece.y + 0.5) * step);
      
      double targetX = target.x.toDouble();
      double targetY = target.y.toDouble();

      if ((targetX - piece.x).abs() > 4.5) {
        if (targetX > piece.x) {
          targetX -= 9;
        } else {
          targetX += 9;
        }
      }
      if ((targetY - piece.y).abs() > 4.5) {
        if (targetY > piece.y) {
          targetY -= 9;
        } else {
          targetY += 9;
        }
      }

      final end = Offset((targetX + 0.5) * step, (targetY + 0.5) * step);

      canvas.drawLine(start, end, paint);

      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowSize = 10.0;
      
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * math.cos(angle - math.pi / 6),
          end.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * math.cos(angle + math.pi / 6),
          end.dy - arrowSize * math.sin(angle + math.pi / 6),
        );
      
      canvas.drawPath(path, paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
