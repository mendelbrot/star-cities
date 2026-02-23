import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/game_models.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final List<Piece> _pieces = [
    Piece(
      id: '1',
      x: 2,
      y: 1,
      type: PieceType.starCity,
      color: Colors.blue,
      isAnchored: true,
    ),
    Piece(
      id: '2',
      x: 1,
      y: 2,
      type: PieceType.parallax,
      color: Colors.blue,
      tetheredToId: '1',
    ),
    Piece(
      id: '3',
      x: 7,
      y: 8,
      type: PieceType.starCity,
      color: Colors.red,
      isAnchored: true,
    ),
    Piece(
      id: '4',
      x: 6,
      y: 7,
      type: PieceType.eclipse,
      color: Colors.red,
      tetheredToId: '3',
    ),
    Piece(
      id: '5',
      x: 5,
      y: 4,
      type: PieceType.starCity,
      color: Colors.blue,
      isAnchored: true,
    ),
    Piece(
      id: '6',
      x: 3,
      y: 2,
      type: PieceType.eclipse,
      color: Colors.blue,
      tetheredToId: '5',
    ),
    Piece(id: '7', x: 0, y: 8, type: PieceType.neutrino, color: Colors.blue),
  ];

  final List<Piece> _trayPieces = [
    Piece(id: 't1', x: 0, y: 0, type: PieceType.neutrino, color: Colors.blue),
    Piece(id: 't2', x: 1, y: 0, type: PieceType.eclipse, color: Colors.blue),
    Piece(id: 't3', x: 2, y: 0, type: PieceType.starCity, color: Colors.blue),
  ];

  String? _selectedPieceId;
  bool _isSelectedFromTray = false;
  bool _isReTethering = false;
  String? _selectedTetherCityId;
  final Map<String, PlannedAction> _plannedMoves = {};

  math.Point<int> _viewCenter = const math.Point(1, 1); // Home Star

  int _toWorld(int local, int center) {
    return (local + center - 4 + 9) % 9;
  }

  Set<math.Point<int>> _getVisibleSquares() {
    final visible = <math.Point<int>>{};
    final bluePieces = _pieces.where((p) => p.color == Colors.blue);

    for (final piece in bluePieces) {
      final range = piece.type.vision;
      for (int dx = -range; dx <= range; dx++) {
        for (int dy = -range; dy <= range; dy++) {
          int tx = (piece.x + dx) % 9;
          int ty = (piece.y + dy) % 9;
          if (tx < 0) tx += 9;
          if (ty < 0) ty += 9;
          visible.add(math.Point(tx, ty));
        }
      }
    }
    return visible;
  }

  void _onSquareTapped(int x, int y) {
    setState(() {
      final visibleSquares = _getVisibleSquares();
      final tappedPiece = _pieces
          .where((p) => p.x == x && p.y == y)
          .firstOrNull;

      // Filter tappedPiece if it is an enemy and not visible
      final effectiveTappedPiece =
          (tappedPiece != null &&
              (tappedPiece.color == Colors.blue ||
                  visibleSquares.contains(math.Point(x, y))))
          ? tappedPiece
          : null;

      if (_isReTethering) {
        if (effectiveTappedPiece != null &&
            effectiveTappedPiece.type == PieceType.starCity &&
            effectiveTappedPiece.color == Colors.blue &&
            effectiveTappedPiece.isAnchored) {
          // Verify distance and capacity
          final ship = _pieces.firstWhere((p) => p.id == _selectedPieceId);
          if (_isWithinDistance(
            ship.x,
            ship.y,
            effectiveTappedPiece.x,
            effectiveTappedPiece.y,
            2,
          )) {
            final currentTethers = _pieces
                .where((p) => p.tetheredToId == effectiveTappedPiece.id)
                .length;
            final plannedTethers = _plannedMoves.values
                .where((a) => a.tetherId == effectiveTappedPiece.id)
                .length;
            if (currentTethers + plannedTethers < 6) {
              final existingAction = _plannedMoves[_selectedPieceId];
              _plannedMoves[_selectedPieceId!] = existingAction != null
                  ? existingAction.copyWith(tetherId: effectiveTappedPiece.id)
                  : PlannedAction(
                      target: math.Point(ship.x, ship.y),
                      tetherId: effectiveTappedPiece.id,
                    );
              _isReTethering = false;
              _selectedPieceId = null;
            }
          }
        } else {
          _isReTethering = false;
          _selectedPieceId = null;
        }
        return;
      }

      if (_selectedPieceId == null) {
        if (effectiveTappedPiece != null &&
            effectiveTappedPiece.color == Colors.blue) {
          _selectedPieceId = effectiveTappedPiece.id;
          _isSelectedFromTray = false;
        }
      } else if (_isSelectedFromTray) {
        final trayPiece = _trayPieces.firstWhere(
          (p) => p.id == _selectedPieceId,
        );
        if (trayPiece.type.requiresTether) {
          if (_selectedTetherCityId == null) {
            if (effectiveTappedPiece != null &&
                effectiveTappedPiece.type == PieceType.starCity &&
                effectiveTappedPiece.color == Colors.blue &&
                effectiveTappedPiece.isAnchored) {
              final currentTethers = _pieces
                  .where((p) => p.tetheredToId == effectiveTappedPiece.id)
                  .length;
              final plannedTethers = _plannedMoves.values
                  .where((a) => a.tetherId == effectiveTappedPiece.id)
                  .length;
              if (currentTethers + plannedTethers < 6) {
                _selectedTetherCityId = effectiveTappedPiece.id;
              }
            } else {
              _selectedPieceId = null;
            }
          } else {
            if (_isValidPlacementSquare(x, y, _selectedTetherCityId!)) {
              _plannedMoves[_selectedPieceId!] = PlannedAction(
                target: math.Point(x, y),
                tetherId: _selectedTetherCityId,
              );
              _selectedPieceId = null;
              _selectedTetherCityId = null;
            } else {
              if (effectiveTappedPiece != null &&
                  effectiveTappedPiece.type == PieceType.starCity &&
                  effectiveTappedPiece.color == Colors.blue &&
                  effectiveTappedPiece.isAnchored) {
                _selectedTetherCityId = effectiveTappedPiece.id;
              } else {
                _selectedPieceId = null;
                _selectedTetherCityId = null;
              }
            }
          }
        } else {
          if (_isValidIndependentPlacement(x, y)) {
            _plannedMoves[_selectedPieceId!] = PlannedAction(
              target: math.Point(x, y),
            );
            _selectedPieceId = null;
          } else {
            _selectedPieceId = null;
          }
        }
      } else {
        final selectedPiece = _pieces.firstWhere(
          (p) => p.id == _selectedPieceId,
        );
        if (effectiveTappedPiece != null &&
            effectiveTappedPiece.id == _selectedPieceId) {
          if (_plannedMoves.containsKey(_selectedPieceId)) {
            _plannedMoves.remove(_selectedPieceId);
          } else {
            _selectedPieceId = null;
          }
        } else if (effectiveTappedPiece != null &&
            effectiveTappedPiece.color == Colors.blue) {
          _selectedPieceId = effectiveTappedPiece.id;
        } else {
          if (_isValidMove(selectedPiece, x, y)) {
            final existingAction = _plannedMoves[_selectedPieceId];
            _plannedMoves[_selectedPieceId!] = existingAction != null
                ? existingAction.copyWith(target: math.Point(x, y))
                : PlannedAction(target: math.Point(x, y));
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
      _isReTethering = false;
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

  bool _isValidMove(Piece piece, int x, int y) {
    if (!_isWithinDistance(piece.x, piece.y, x, y, piece.type.movement)) {
      return false;
    }
    if (_pieces.any((p) => p.x == x && p.y == y)) {
      return false;
    }
    if (_plannedMoves.values.any((a) => a.target.x == x && a.target.y == y)) {
      return false;
    }

    final plannedTetherId = _plannedMoves[piece.id]?.tetherId;
    final cityId = plannedTetherId ?? piece.tetheredToId;

    if (piece.type.requiresTether && cityId != null) {
      final city = _pieces.firstWhere((p) => p.id == cityId);
      int dx = (x - city.x).abs();
      int dy = (y - city.y).abs();
      dx = math.min(dx, 9 - dx);
      dy = math.min(dy, 9 - dy);
      if (math.max(dx, dy) > 2) return false;
    }

    if (piece.type == PieceType.starCity) {
      if (piece.isAnchored) {
        final hasTethers = _pieces.any((p) => p.tetheredToId == piece.id);
        if (hasTethers) return false;
      }
    }

    return true;
  }

  bool _isValidPlacementSquare(int x, int y, String tetherCityId) {
    final city = _pieces.firstWhere((p) => p.id == tetherCityId);
    final isOccupiedByPiece = _pieces.any((p) => p.x == x && p.y == y);
    final isOccupiedByPlan = _plannedMoves.values.any(
      (p) => p.target.x == x && p.target.y == y,
    );
    if (isOccupiedByPiece || isOccupiedByPlan) return false;
    return _isWithinDistance(city.x, city.y, x, y, 1);
  }

  bool _isValidIndependentPlacement(int x, int y) {
    final isOccupiedByPiece = _pieces.any((p) => p.x == x && p.y == y);
    final isOccupiedByPlan = _plannedMoves.values.any(
      (p) => p.target.x == x && p.target.y == y,
    );
    if (isOccupiedByPiece || isOccupiedByPlan) return false;
    final blueCities = _pieces.where(
      (p) =>
          p.type == PieceType.starCity &&
          p.color == Colors.blue &&
          p.isAnchored,
    );
    for (final city in blueCities) {
      if (_isWithinDistance(city.x, city.y, x, y, 1)) return true;
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

    final isBesideStar =
        selectedBoardPiece != null &&
        _isAdjacentToStar(selectedBoardPiece.x, selectedBoardPiece.y);

    // Calculate effective tethers accounting for planned re-tethers and placements
    int effectiveTethers = 0;
    if (selectedBoardPiece != null) {
      effectiveTethers =
          _pieces.where((p) {
            final plannedAction = _plannedMoves[p.id];
            final tetherId = plannedAction?.tetherId ?? p.tetheredToId;
            return tetherId == selectedBoardPiece.id;
          }).length +
          _trayPieces.where((p) {
            final plannedAction = _plannedMoves[p.id];
            return plannedAction?.tetherId == selectedBoardPiece.id;
          }).length;
    }

    final showAnchor =
        selectedBoardPiece != null &&
        selectedBoardPiece.type == PieceType.starCity &&
        !selectedBoardPiece.isAnchored &&
        isBesideStar;

    final showDeAnchor =
        selectedBoardPiece != null &&
        selectedBoardPiece.type == PieceType.starCity &&
        selectedBoardPiece.isAnchored &&
        effectiveTethers == 0;

    final showBombard =
        selectedBoardPiece != null &&
        selectedBoardPiece.type == PieceType.eclipse;

    // Show Re-tether if piece is a ship and there are other anchored cities in range 2 with capacity
    bool showReTether = false;
    if (selectedBoardPiece != null &&
        selectedBoardPiece.type != PieceType.starCity &&
        selectedBoardPiece.type.requiresTether) {
      final effectiveTetherId =
          _plannedMoves[selectedBoardPiece.id]?.tetherId ??
          selectedBoardPiece.tetheredToId;

      final otherAnchoredCities = _pieces.where(
        (p) =>
            p.type == PieceType.starCity &&
            p.color == Colors.blue &&
            p.isAnchored &&
            p.id != effectiveTetherId,
      );

      for (final city in otherAnchoredCities) {
        if (_isWithinDistance(
          selectedBoardPiece.x,
          selectedBoardPiece.y,
          city.x,
          city.y,
          2,
        )) {
          // Calculate effective tethers for this city
          int cityEffectiveTethers =
              _pieces.where((p) {
                final plannedTetherId =
                    _plannedMoves[p.id]?.tetherId ?? p.tetheredToId;
                return plannedTetherId == city.id;
              }).length +
              _trayPieces.where((p) {
                return _plannedMoves[p.id]?.tetherId == city.id;
              }).length;

          if (cityEffectiveTethers < 6) {
            showReTether = true;
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Star Cities'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(
                    () => _viewCenter = math.Point(
                      (_viewCenter.x - 1 + 9) % 9,
                      _viewCenter.y,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, color: Colors.white),
                  onPressed: () => setState(
                    () => _viewCenter = math.Point(
                      _viewCenter.x,
                      (_viewCenter.y + 1 + 9) % 9,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.yellow),
                  onPressed: () =>
                      setState(() => _viewCenter = const math.Point(1, 1)),
                ),

                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: () => setState(
                    () => _viewCenter = math.Point(
                      _viewCenter.x,
                      (_viewCenter.y - 1 + 9) % 9,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () => setState(
                    () => _viewCenter = math.Point(
                      (_viewCenter.x + 1 + 9) % 9,
                      _viewCenter.y,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final step = constraints.maxWidth / 9;
                  return GestureDetector(
                    onTapUp: (details) {
                      final lx = details.localPosition.dx ~/ step;
                      final ly = details.localPosition.dy ~/ step;
                      if (lx >= 0 && lx < 9 && ly >= 0 && ly < 9) {
                        final x = _toWorld(lx, _viewCenter.x);
                        final y = _toWorld(ly, _viewCenter.y);
                        _onSquareTapped(x, y);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const SpaceGrid(),
                          StarOverlay(viewCenter: _viewCenter),
                          TetherOverlay(
                            pieces: _pieces,
                            plannedMoves: _plannedMoves,
                            trayPieces: _trayPieces,
                            viewCenter: _viewCenter,
                          ),
                          if (_selectedPieceId != null)
                            ValidMoveMarkers(
                              selectedPiece: _isSelectedFromTray
                                  ? _trayPieces.firstWhere(
                                      (p) => p.id == _selectedPieceId,
                                    )
                                  : _pieces.firstWhere(
                                      (p) => p.id == _selectedPieceId,
                                    ),
                              isSelectedFromTray: _isSelectedFromTray,
                              isReTethering: _isReTethering,
                              selectedTetherCityId: _selectedTetherCityId,
                              pieces: _pieces,
                              trayPieces: _trayPieces,
                              plannedMoves: _plannedMoves,
                              viewCenter: _viewCenter,
                              isValidMove: (p, x, y) => _isValidMove(p, x, y),
                              isValidPlacement: (x, y, tId) =>
                                  _isValidPlacementSquare(x, y, tId),
                              isValidIndependent: (x, y) =>
                                  _isValidIndependentPlacement(x, y),
                            ),
                          PlannedMoveArrows(
                            pieces: _pieces,
                            plannedMoves: _plannedMoves,
                            viewCenter: _viewCenter,
                          ),
                          PieceOverlay(
                            pieces: _pieces.where((p) {
                              if (p.color == Colors.blue) {
                                return true;
                              }
                              final visibleSquares = _getVisibleSquares();
                              if (!visibleSquares.contains(
                                math.Point(p.x, p.y),
                              )) {
                                return false;
                              }
                              if (p.type == PieceType.neutrino) {
                                return false; // Cloaked
                              }
                              return true;
                            }).toList(),
                            selectedPieceId: _isSelectedFromTray
                                ? null
                                : _selectedPieceId,
                            plannedMoves: _plannedMoves,
                            viewCenter: _viewCenter,
                          ),
                          FogOverlay(
                            visibleSquares: _getVisibleSquares(),
                            viewCenter: _viewCenter,
                          ),
                          PlannedPlacementOverlay(
                            trayPieces: _trayPieces,
                            plannedMoves: _plannedMoves,
                            viewCenter: _viewCenter,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const SpaceGrid(rows: 1, cols: 9),
                          PieceOverlay(
                            pieces: _trayPieces,
                            selectedPieceId: _isSelectedFromTray
                                ? _selectedPieceId
                                : null,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (showAnchor)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                final index = _pieces.indexWhere(
                                  (p) => p.id == _selectedPieceId,
                                );
                                _pieces[index] = _pieces[index].copyWith(
                                  isAnchored: true,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            child: const Text('Anchor'),
                          ),
                        ),
                      if (showDeAnchor)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                final index = _pieces.indexWhere(
                                  (p) => p.id == _selectedPieceId,
                                );
                                _pieces[index] = _pieces[index].copyWith(
                                  isAnchored: false,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            child: const Text('De-anchor'),
                          ),
                        ),
                      if (showReTether)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isReTethering = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReTethering
                                  ? Colors.yellow
                                  : null,
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            child: const Text('Re-tether'),
                          ),
                        ),
                      if (showBombard)
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                          ),
                          child: const Text('Bombard'),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _plannedMoves.clear();
                            _selectedPieceId = null;
                            _isSelectedFromTray = false;
                            _selectedTetherCityId = null;
                            _isReTethering = false;
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
      canvas.drawLine(
        Offset(i * stepX, 0),
        Offset(i * stepX, size.height),
        paint,
      );
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(0, i * stepY),
        Offset(size.width, i * stepY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarOverlay extends StatelessWidget {
  final math.Point<int> viewCenter;
  const StarOverlay({super.key, required this.viewCenter});

  @override
  Widget build(BuildContext context) {
    final stars = [(1, 1), (3, 5), (6, 2), (7, 7), (2, 6), (5, 3)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        return Stack(
          children: stars.map((pos) {
            final lx = (pos.$1 - viewCenter.x + 4 + 9) % 9;
            final ly = (pos.$2 - viewCenter.y + 4 + 9) % 9;
            return Positioned(
              left: lx * step + step * 0.1,
              top: ly * step + step * 0.1,
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
  final math.Point<int> viewCenter;

  const PieceOverlay({
    super.key,
    required this.pieces,
    this.selectedPieceId,
    this.rows = 9,
    this.cols = 9,
    this.plannedMoves = const {},
    this.viewCenter = const math.Point(
      4,
      4,
    ), // Default center if not board view
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

              final lx = (p.x - viewCenter.x + 4 + 9) % 9;
              final ly = (p.y - viewCenter.y + 4 + 9) % 9;

              return Positioned(
                left: (rows == 1 ? p.x : lx) * stepX,
                top: (rows == 1 ? p.y : ly) * stepY,
                width: stepX,
                height: stepY,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: hasPlan ? 0.3 : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(stepX * 0.2),
                      decoration: isSelected
                          ? BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withValues(alpha: 0.1),
                            )
                          : null,
                      child: PieceWidget(
                        type: p.type,
                        color: p.color,
                        isAnchored: p.isAnchored,
                      ),
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

class PieceWidget extends StatelessWidget {
  final PieceType type;
  final Color color;
  final bool isAnchored;

  const PieceWidget({
    super.key,
    required this.type,
    required this.color,
    this.isAnchored = false,
  });

  @override
  Widget build(BuildContext context) {
    if (type == PieceType.starCity) {
      return StarCityWidget(color: color, isAnchored: isAnchored);
    }
    return CustomPaint(
      painter: ShipPainter(type: type, color: color),
    );
  }
}

class StarCityWidget extends StatelessWidget {
  final Color color;
  final bool isAnchored;

  const StarCityWidget({
    super.key,
    required this.color,
    required this.isAnchored,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: isAnchored
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Icon(Icons.location_city, color: Colors.white, size: 16),
          ),
          if (isAnchored)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Icon(Icons.anchor, color: color, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class ShipPainter extends CustomPainter {
  final PieceType type;
  final Color color;
  ShipPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (type == PieceType.eclipse) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    } else if (type == PieceType.neutrino) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(0, size.height / 2);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (type == PieceType.eclipse) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, borderPaint);
    } else {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FogOverlay extends StatelessWidget {
  final Set<math.Point<int>> visibleSquares;
  final math.Point<int> viewCenter;
  const FogOverlay({
    super.key,
    required this.visibleSquares,
    required this.viewCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        final List<Widget> fogSquares = [];

        for (int x = 0; x < 9; x++) {
          for (int y = 0; y < 9; y++) {
            if (!visibleSquares.contains(math.Point(x, y))) {
              final lx = (x - viewCenter.x + 4 + 9) % 9;
              final ly = (y - viewCenter.y + 4 + 9) % 9;
              fogSquares.add(
                Positioned(
                  left: lx * step,
                  top: ly * step,
                  width: step,
                  height: step,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }
          }
        }
        return Stack(children: fogSquares);
      },
    );
  }
}

class PlannedPlacementOverlay extends StatelessWidget {
  final List<Piece> trayPieces;
  final Map<String, PlannedAction> plannedMoves;
  final math.Point<int> viewCenter;

  const PlannedPlacementOverlay({
    super.key,
    required this.trayPieces,
    required this.plannedMoves,
    required this.viewCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        final widgets = <Widget>[];

        plannedMoves.forEach((pieceId, action) {
          final trayPiece = trayPieces
              .where((p) => p.id == pieceId)
              .firstOrNull;
          if (trayPiece != null) {
            final lx = (action.target.x - viewCenter.x + 4 + 9) % 9;
            final ly = (action.target.y - viewCenter.y + 4 + 9) % 9;
            widgets.add(
              Positioned(
                left: lx * step,
                top: ly * step,
                width: step,
                height: step,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    padding: EdgeInsets.all(step * 0.2),
                    child: PieceWidget(
                      type: trayPiece.type,
                      color: trayPiece.color,
                      isAnchored: trayPiece.isAnchored,
                    ),
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
  final bool isReTethering;
  final String? selectedTetherCityId;
  final List<Piece> pieces;
  final List<Piece> trayPieces;
  final Map<String, PlannedAction> plannedMoves;
  final math.Point<int> viewCenter;
  final bool Function(Piece, int, int) isValidMove;
  final bool Function(int, int, String) isValidPlacement;
  final bool Function(int, int) isValidIndependent;

  const ValidMoveMarkers({
    super.key,
    required this.selectedPiece,
    required this.isSelectedFromTray,
    this.isReTethering = false,
    this.selectedTetherCityId,
    required this.pieces,
    required this.trayPieces,
    required this.plannedMoves,
    required this.viewCenter,
    required this.isValidMove,
    required this.isValidPlacement,
    required this.isValidIndependent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / 9;
        List<Widget> markers = [];

        if (isReTethering) {
          final effectiveTetherId =
              plannedMoves[selectedPiece.id]?.tetherId ??
              selectedPiece.tetheredToId;

          final otherAnchoredCities = pieces.where(
            (p) =>
                p.type == PieceType.starCity &&
                p.color == Colors.blue &&
                p.isAnchored &&
                p.id != effectiveTetherId,
          );
          for (final city in otherAnchoredCities) {
            int dx = (city.x - selectedPiece.x).abs();
            int dy = (city.y - selectedPiece.y).abs();
            dx = math.min(dx, 9 - dx);
            dy = math.min(dy, 9 - dy);

            if (math.max(dx, dy) <= 2) {
              int cityEffectiveTethers =
                  pieces.where((p) {
                    final plannedTetherId =
                        plannedMoves[p.id]?.tetherId ?? p.tetheredToId;
                    return plannedTetherId == city.id;
                  }).length +
                  trayPieces.where((p) {
                    return plannedMoves[p.id]?.tetherId == city.id;
                  }).length;

              if (cityEffectiveTethers < 6) {
                final lx = (city.x - viewCenter.x + 4 + 9) % 9;
                final ly = (city.y - viewCenter.y + 4 + 9) % 9;
                markers.add(
                  Positioned(
                    left: lx * step,
                    top: ly * step,
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
          }
        } else if (isSelectedFromTray) {
          if (selectedPiece.type.requiresTether) {
            if (selectedTetherCityId == null) {
              final blueCities = pieces.where(
                (p) =>
                    p.type == PieceType.starCity &&
                    p.color == Colors.blue &&
                    p.isAnchored,
              );
              for (final city in blueCities) {
                int cityEffectiveTethers =
                    pieces.where((p) {
                      final plannedTetherId =
                          plannedMoves[p.id]?.tetherId ?? p.tetheredToId;
                      return plannedTetherId == city.id;
                    }).length +
                    trayPieces.where((p) {
                      return plannedMoves[p.id]?.tetherId == city.id;
                    }).length;

                if (cityEffectiveTethers < 6) {
                  final lx = (city.x - viewCenter.x + 4 + 9) % 9;
                  final ly = (city.y - viewCenter.y + 4 + 9) % 9;
                  markers.add(
                    Positioned(
                      left: lx * step,
                      top: ly * step,
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
              final city = pieces.firstWhere(
                (p) => p.id == selectedTetherCityId,
              );
              for (int dx = -1; dx <= 1; dx++) {
                for (int dy = -1; dy <= 1; dy++) {
                  if (dx == 0 && dy == 0) continue;
                  int tx = (city.x + dx) % 9;
                  int ty = (city.y + dy) % 9;
                  if (tx < 0) tx += 9;
                  if (ty < 0) ty += 9;
                  if (isValidPlacement(tx, ty, selectedTetherCityId!)) {
                    final lx = (tx - viewCenter.x + 4 + 9) % 9;
                    final ly = (ty - viewCenter.y + 4 + 9) % 9;
                    markers.add(_buildMarker(lx, ly, step));
                  }
                }
              }
            }
          } else {
            for (int x = 0; x < 9; x++) {
              for (int y = 0; y < 9; y++) {
                if (isValidIndependent(x, y)) {
                  final lx = (x - viewCenter.x + 4 + 9) % 9;
                  final ly = (y - viewCenter.y + 4 + 9) % 9;
                  markers.add(_buildMarker(lx, ly, step));
                }
              }
            }
          }
        } else {
          int range = selectedPiece.type.movement;
          for (int dx = -range; dx <= range; dx++) {
            for (int dy = -range; dy <= range; dy++) {
              if (dx == 0 && dy == 0) continue;
              int tx = (selectedPiece.x + dx) % 9;
              int ty = (selectedPiece.y + dy) % 9;
              if (tx < 0) tx += 9;
              if (ty < 0) ty += 9;
              if (isValidMove(selectedPiece, tx, ty)) {
                final lx = (tx - viewCenter.x + 4 + 9) % 9;
                final ly = (ty - viewCenter.y + 4 + 9) % 9;
                markers.add(_buildMarker(lx, ly, step));
              }
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
  final math.Point<int> viewCenter;

  const TetherOverlay({
    super.key,
    required this.pieces,
    required this.trayPieces,
    required this.plannedMoves,
    required this.viewCenter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: TetherPainter(
        pieces: pieces,
        trayPieces: trayPieces,
        plannedMoves: plannedMoves,
        viewCenter: viewCenter,
      ),
    );
  }
}

class TetherPainter extends CustomPainter {
  final List<Piece> pieces;
  final List<Piece> trayPieces;
  final Map<String, PlannedAction> plannedMoves;
  final math.Point<int> viewCenter;

  TetherPainter({
    required this.pieces,
    required this.trayPieces,
    required this.plannedMoves,
    required this.viewCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;

    for (final piece in pieces) {
      final plannedTetherId = plannedMoves[piece.id]?.tetherId;
      final cityId = piece.tetheredToId;

      if (cityId != null && plannedTetherId == null) {
        final city = pieces.where((p) => p.id == cityId).firstOrNull;
        if (city != null) {
          final lx1 = (piece.x - viewCenter.x + 4 + 9) % 9;
          final ly1 = (piece.y - viewCenter.y + 4 + 9) % 9;
          final lx2 = (city.x - viewCenter.x + 4 + 9) % 9;
          final ly2 = (city.y - viewCenter.y + 4 + 9) % 9;
          _drawTether(canvas, lx1, ly1, lx2, ly2, piece.color, step, false);
        }
      }
    }

    plannedMoves.forEach((pieceId, action) {
      if (action.tetherId != null) {
        final trayPiece = trayPieces.where((p) => p.id == pieceId).firstOrNull;
        final boardPiece = pieces.where((p) => p.id == pieceId).firstOrNull;
        final color = trayPiece?.color ?? boardPiece?.color ?? Colors.white;

        final city = pieces.where((p) => p.id == action.tetherId).firstOrNull;
        if (city != null) {
          final lx1 = (action.target.x - viewCenter.x + 4 + 9) % 9;
          final ly1 = (action.target.y - viewCenter.y + 4 + 9) % 9;
          final lx2 = (city.x - viewCenter.x + 4 + 9) % 9;
          final ly2 = (city.y - viewCenter.y + 4 + 9) % 9;
          _drawTether(canvas, lx1, ly1, lx2, ly2, color, step, true);
        }
      }
    });
  }

  void _drawTether(
    Canvas canvas,
    int x1,
    int y1,
    int x2,
    int y2,
    Color color,
    double step,
    bool isPlanned,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final start = Offset((x1 + 0.5) * step, (y1 + 0.5) * step);
    final end = Offset((x2 + 0.5) * step, (y2 + 0.5) * step);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlannedMoveArrows extends StatelessWidget {
  final List<Piece> pieces;
  final Map<String, PlannedAction> plannedMoves;
  final math.Point<int> viewCenter;

  const PlannedMoveArrows({
    super.key,
    required this.pieces,
    required this.plannedMoves,
    required this.viewCenter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: ArrowPainter(
        pieces: pieces,
        plannedMoves: plannedMoves,
        viewCenter: viewCenter,
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final List<Piece> pieces;
  final Map<String, PlannedAction> plannedMoves;
  final math.Point<int> viewCenter;

  ArrowPainter({
    required this.pieces,
    required this.plannedMoves,
    required this.viewCenter,
  });

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

      if (action.target.x == piece.x && action.target.y == piece.y) return;

      final lx1 = (piece.x - viewCenter.x + 4 + 9) % 9;
      final ly1 = (piece.y - viewCenter.y + 4 + 9) % 9;
      final lx2 = (action.target.x - viewCenter.x + 4 + 9) % 9;
      final ly2 = (action.target.y - viewCenter.y + 4 + 9) % 9;

      final start = Offset((lx1 + 0.5) * step, (ly1 + 0.5) * step);
      final end = Offset((lx2 + 0.5) * step, (ly2 + 0.5) * step);
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
