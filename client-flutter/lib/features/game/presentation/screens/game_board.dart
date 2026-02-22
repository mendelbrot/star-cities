import 'package:flutter/material.dart';
import 'dart:math' as math;

class Piece {
  final String id;
  final int x;
  final int y;
  final String type;
  final Color color;
  final String? tetheredToId; // ID of the Star City this piece is tethered to

  Piece({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.color,
    this.tetheredToId,
  });

  Piece copyWith({int? x, int? y, String? tetheredToId}) {
    return Piece(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type,
      color: color,
      tetheredToId: tetheredToId ?? this.tetheredToId,
    );
  }
}

class PlannedAction {
  final math.Point<int> target;
  final String? tetherId; // For new placements from tray

  PlannedAction({required this.target, this.tetherId});
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final List<Piece> _pieces = [
    Piece(id: '1', x: 2, y: 1, type: 'Star City', color: Colors.blue),
    Piece(id: '2', x: 1, y: 2, type: 'Ship', color: Colors.blue, tetheredToId: '1'),
    Piece(id: '3', x: 7, y: 8, type: 'Star City', color: Colors.red),
    Piece(id: '4', x: 6, y: 7, type: 'Ship', color: Colors.red, tetheredToId: '3'),
  ];

  final List<Piece> _trayPieces = [
    Piece(id: 't1', x: 0, y: 0, type: 'Ship', color: Colors.blue),
    Piece(id: 't2', x: 1, y: 0, type: 'Ship', color: Colors.blue),
    Piece(id: 't3', x: 2, y: 0, type: 'Star City', color: Colors.blue),
  ];

  String? _selectedPieceId;
  bool _isSelectedFromTray = false;
  String? _selectedTetherCityId; // For step 2 of placement
  final Map<String, PlannedAction> _plannedMoves = {};

  void _onSquareTapped(int x, int y) {
    setState(() {
      final tappedPiece = _pieces.where((p) => p.x == x && p.y == y).firstOrNull;

      if (_selectedPieceId == null) {
        if (tappedPiece != null) {
          _selectedPieceId = tappedPiece.id;
          _isSelectedFromTray = false;
        }
      } else if (_isSelectedFromTray) {
        // Placement Flow
        if (_selectedTetherCityId == null) {
          // Step 2: Selecting Star City to tether to
          if (tappedPiece != null && tappedPiece.type == 'Star City' && tappedPiece.color == Colors.blue) {
            // Check if city has room (limit 6)
            final currentTethers = _pieces.where((p) => p.tetheredToId == tappedPiece.id).length;
            final plannedTethers = _plannedMoves.values.where((a) => a.tetherId == tappedPiece.id).length;
            if (currentTethers + plannedTethers < 6) {
              _selectedTetherCityId = tappedPiece.id;
            }
          } else {
            _selectedPieceId = null;
          }
        } else {
          // Step 3: Selecting Square
          if (_isValidPlacementSquare(x, y, _selectedTetherCityId!)) {
            _plannedMoves[_selectedPieceId!] = PlannedAction(
              target: math.Point(x, y),
              tetherId: _selectedTetherCityId,
            );
            _selectedPieceId = null;
            _selectedTetherCityId = null;
          } else {
            // If tapped a different star city, switch tether
            if (tappedPiece != null && tappedPiece.type == 'Star City' && tappedPiece.color == Colors.blue) {
              _selectedTetherCityId = tappedPiece.id;
            } else {
              _selectedPieceId = null;
              _selectedTetherCityId = null;
            }
          }
        }
      } else {
        // Move Flow for board pieces
        final selectedPiece = _pieces.firstWhere((p) => p.id == _selectedPieceId);

        if (tappedPiece != null && tappedPiece.id == _selectedPieceId) {
          if (_plannedMoves.containsKey(_selectedPieceId)) {
            _plannedMoves.remove(_selectedPieceId);
          } else {
            _selectedPieceId = null;
          }
        } else if (tappedPiece != null) {
          _selectedPieceId = tappedPiece.id;
        } else {
          if (_isWithinDistance(selectedPiece.x, selectedPiece.y, x, y, 2)) {
            _plannedMoves[_selectedPieceId!] = PlannedAction(target: math.Point(x, y));
            _selectedPieceId = null;
          } else {
            _selectedPieceId = null;
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
        _selectedTetherCityId = null;
        return;
      }

      if (_plannedMoves.containsKey(tappedPiece.id)) {
        _plannedMoves.remove(tappedPiece.id);
        _selectedPieceId = tappedPiece.id;
        _isSelectedFromTray = true;
        _selectedTetherCityId = null;
      } else if (_selectedPieceId == tappedPiece.id) {
        _selectedPieceId = null;
        _selectedTetherCityId = null;
      } else {
        _selectedPieceId = tappedPiece.id;
        _isSelectedFromTray = true;
        _selectedTetherCityId = null;
      }
    });
  }

  bool _isValidPlacementSquare(int x, int y, String tetherCityId) {
    final city = _pieces.firstWhere((p) => p.id == tetherCityId);
    
    // Check if occupied
    final isOccupiedByPiece = _pieces.any((p) => p.x == x && p.y == y);
    final isOccupiedByPlan = _plannedMoves.values.any((p) => p.target.x == x && p.target.y == y);
    if (isOccupiedByPiece || isOccupiedByPlan) return false;

    // Must be distance 1 from the selected tether star city
    return _isWithinDistance(city.x, city.y, x, y, 1);
  }

  bool _isWithinDistance(int x1, int y1, int x2, int y2, int distance) {
    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();
    dx = math.min(dx, 9 - dx);
    dy = math.min(dy, 9 - dy);
    return math.max(dx, dy) <= distance && math.max(dx, dy) > 0;
  }

  bool _isAdjacentToStar(int x, int y) {
    final stars = [(1, 1), (3, 5), (6, 2), (7, 7), (2, 6), (5, 3)];
    for (var star in stars) {
      if ((x - star.$1).abs() <= 1 && (y - star.$2).abs() <= 1) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBoardPiece = !_isSelectedFromTray 
      ? _pieces.where((p) => p.id == _selectedPieceId).firstOrNull
      : null;

    final showAnchor = selectedBoardPiece != null && 
                       selectedBoardPiece.type == 'Star City' && 
                       _isAdjacentToStar(selectedBoardPiece.x, selectedBoardPiece.y);
    final showBombard = selectedBoardPiece != null && 
                        selectedBoardPiece.type == 'Ship';

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
                          // Tethers
                          TetherOverlay(
                            pieces: _pieces,
                            plannedMoves: _plannedMoves,
                            trayPieces: _trayPieces,
                          ),
                          if (_selectedPieceId != null)
                            ValidMoveMarkers(
                              selectedPiece: _isSelectedFromTray 
                                ? _trayPieces.firstWhere((p) => p.id == _selectedPieceId)
                                : _pieces.firstWhere((p) => p.id == _selectedPieceId),
                              isSelectedFromTray: _isSelectedFromTray,
                              selectedTetherCityId: _selectedTetherCityId,
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
          // Pieces Tray
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
          const Spacer(),
          // Button Tray
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Contextual actions
                  Row(
                    children: [
                      if (showAnchor)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {}, 
                            style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF0F172A)),
                            child: const Text('Anchor'),
                          ),
                        ),
                      if (showBombard)
                        ElevatedButton(
                          onPressed: () {}, 
                          style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF0F172A)),
                          child: const Text('Bombard'),
                        ),
                    ],
                  ),
                  // Right side: Reset and Done
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _plannedMoves.clear();
                            _selectedPieceId = null;
                            _isSelectedFromTray = false;
                            _selectedTetherCityId = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
  final Map<String, PlannedAction> plannedMoves;

  const PieceOverlay({
    super.key,
    required this.pieces,
    this.selectedPieceId,
    this.rows = 9,
    this.cols = 9,
    this.plannedMoves = const {},
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
  final Map<String, PlannedAction> plannedMoves;

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

        plannedMoves.forEach((pieceId, action) {
          final trayPiece = trayPieces.where((p) => p.id == pieceId).firstOrNull;
          if (trayPiece != null) {
            widgets.add(
              Positioned(
                left: action.target.x * step,
                top: action.target.y * step,
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
  final String? selectedTetherCityId;
  final List<Piece> pieces;
  final Map<String, PlannedAction> plannedMoves;

  const ValidMoveMarkers({
    super.key,
    required this.selectedPiece,
    required this.isSelectedFromTray,
    this.selectedTetherCityId,
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
          if (selectedTetherCityId == null) {
            // Step 2: Highlight available Star Cities
            final blueStarCities = pieces.where((p) => p.type == 'Star City' && p.color == Colors.blue);
            for (final city in blueStarCities) {
              // Check capacity
              final currentTethers = pieces.where((p) => p.tetheredToId == city.id).length;
              final plannedTethers = plannedMoves.values.where((a) => a.tetherId == city.id).length;
              if (currentTethers + plannedTethers < 6) {
                markers.add(
                  Positioned(
                    left: city.x * step,
                    top: city.y * step,
                    width: step,
                    height: step,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.yellow, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          } else {
            // Step 3: Show squares around selected tether city
            final city = pieces.firstWhere((p) => p.id == selectedTetherCityId);
            for (int dx = -1; dx <= 1; dx++) {
              for (int dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) continue;
                int tx = (city.x + dx) % 9;
                int ty = (city.y + dy) % 9;
                if (tx < 0) tx += 9;
                if (ty < 0) ty += 9;

                final isOccupiedByPiece = pieces.any((p) => p.x == tx && p.y == ty);
                final isOccupiedByPlan = plannedMoves.values.any((p) => p.target.x == tx && p.target.y == ty);
                
                if (!isOccupiedByPiece && !isOccupiedByPlan) {
                  markers.add(_buildMarker(tx, ty, step));
                }
              }
            }
          }
        } else {
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

class TetherOverlay extends StatelessWidget {
  final List<Piece> pieces;
  final List<Piece> trayPieces;
  final Map<String, PlannedAction> plannedMoves;

  const TetherOverlay({
    super.key,
    required this.pieces,
    required this.trayPieces,
    required this.plannedMoves,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: TetherPainter(
        pieces: pieces,
        trayPieces: trayPieces,
        plannedMoves: plannedMoves,
      ),
    );
  }
}

class TetherPainter extends CustomPainter {
  final List<Piece> pieces;
  final List<Piece> trayPieces;
  final Map<String, PlannedAction> plannedMoves;

  TetherPainter({
    required this.pieces,
    required this.trayPieces,
    required this.plannedMoves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;

    // Draw current tethers
    for (final piece in pieces) {
      if (piece.tetheredToId != null) {
        final city = pieces.firstWhere((p) => p.id == piece.tetheredToId);
        _drawTether(canvas, piece.x, piece.y, city.x, city.y, piece.color, step, false);
      }
    }

    // Draw planned placement tethers
    plannedMoves.forEach((pieceId, action) {
      if (action.tetherId != null) {
        final trayPiece = trayPieces.firstWhere((p) => p.id == pieceId);
        final city = pieces.firstWhere((p) => p.id == action.tetherId);
        _drawTether(canvas, action.target.x, action.target.y, city.x, city.y, trayPiece.color, step, true);
      }
    });
  }

  void _drawTether(Canvas canvas, int x1, int y1, int x2, int y2, Color color, double step, bool isPlanned) {
    final paint = Paint()
      ..color = color.withValues(alpha: isPlanned ? 0.3 : 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final start = Offset((x1 + 0.5) * step, (y1 + 0.5) * step);
    
    // Torus shortest path
    double targetX = x2.toDouble();
    double targetY = y2.toDouble();

    if ((targetX - x1).abs() > 4.5) {
      if (targetX > x1) {
        targetX -= 9;
      } else {
        targetX += 9;
      }
    }
    if ((targetY - y1).abs() > 4.5) {
      if (targetY > y1) {
        targetY -= 9;
      } else {
        targetY += 9;
      }
    }

    final end = Offset((targetX + 0.5) * step, (targetY + 0.5) * step);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlannedMoveArrows extends StatelessWidget {
  final List<Piece> pieces;
  final Map<String, PlannedAction> plannedMoves;

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
  final Map<String, PlannedAction> plannedMoves;

  ArrowPainter({required this.pieces, required this.plannedMoves});

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    plannedMoves.forEach((pieceId, action) {
      final piece = pieces.where((p) => p.id == pieceId).firstOrNull;
      if (piece == null) return;
      
      final start = Offset((piece.x + 0.5) * step, (piece.y + 0.5) * step);
      
      double targetX = action.target.x.toDouble();
      double targetY = action.target.y.toDouble();

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
