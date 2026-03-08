import 'dart:math' as math;

sealed class GameAction {
  final String type;
  const GameAction(this.type);

  factory GameAction.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'MOVE_ACT':
        return MoveAction.fromMap(map);
      case 'BOMBARD_ACT':
        return BombardAction.fromMap(map);
      case 'TETHER_ACT':
        return TetherAction.fromMap(map);
      case 'ANCHOR_ACT':
        return AnchorAction.fromMap(map);
      case 'PLACE_ACT':
        return PlaceAction.fromMap(map);
      default:
        throw Exception('Unknown action type: $type');
    }
  }

  Map<String, dynamic> toMap();
}

class MoveAction extends GameAction {
  final String pieceId;
  final math.Point<int> to;

  const MoveAction({required this.pieceId, required this.to}) : super('MOVE_ACT');

  factory MoveAction.fromMap(Map<String, dynamic> map) {
    return MoveAction(
      pieceId: map['piece_id'],
      to: math.Point(map['to']['x'], map['to']['y']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': type,
    'piece_id': pieceId,
    'to': {'x': to.x, 'y': to.y},
  };
}

class BombardAction extends GameAction {
  final String pieceId;
  final String targetId;

  const BombardAction({required this.pieceId, required this.targetId}) : super('BOMBARD_ACT');

  factory BombardAction.fromMap(Map<String, dynamic> map) {
    return BombardAction(
      pieceId: map['piece_id'],
      targetId: map['target_id'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': type,
    'piece_id': pieceId,
    'target_id': targetId,
  };
}

class TetherAction extends GameAction {
  final String shipId;
  final String cityId;

  const TetherAction({required this.shipId, required this.cityId}) : super('TETHER_ACT');

  factory TetherAction.fromMap(Map<String, dynamic> map) {
    return TetherAction(
      shipId: map['ship_id'],
      cityId: map['city_id'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': type,
    'ship_id': shipId,
    'city_id': cityId,
  };
}

class AnchorAction extends GameAction {
  final String pieceId;
  final bool isAnchored;

  const AnchorAction({required this.pieceId, required this.isAnchored}) : super('ANCHOR_ACT');

  factory AnchorAction.fromMap(Map<String, dynamic> map) {
    return AnchorAction(
      pieceId: map['piece_id'],
      isAnchored: map['is_anchored'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': type,
    'piece_id': pieceId,
    'is_anchored': isAnchored,
  };
}

class PlaceAction extends GameAction {
  final String trayPieceId;
  final String? cityId;
  final math.Point<int> target;

  const PlaceAction({
    required this.trayPieceId,
    this.cityId,
    required this.target,
  }) : super('PLACE_ACT');

  factory PlaceAction.fromMap(Map<String, dynamic> map) {
    return PlaceAction(
      trayPieceId: map['tray_piece_id'],
      cityId: map['city_id'],
      target: math.Point(map['target']['x'], map['target']['y']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': type,
    'tray_piece_id': trayPieceId,
    'city_id': cityId,
    'target': {'x': target.x, 'y': target.y},
  };
}
