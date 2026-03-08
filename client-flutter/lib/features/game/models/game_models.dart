import 'dart:math' as math;
import 'package:star_cities/shared/models/faction.dart';

enum PieceType {
  starCity('Star City', 8, 1, 2, false),
  neutrino('Neutrino', 2, 1, 1, false),
  eclipse('Eclipse', 4, 1, 2, true),
  parallax('Parallax', 6, 2, 2, true);

  final String label;
  final int strength;
  final int movement;
  final int vision;
  final bool requiresTether;

  const PieceType(this.label, this.strength, this.movement, this.vision, this.requiresTether);

  static PieceType fromString(String type) {
    final clean = type.toUpperCase().replaceAll('_', '');
    return PieceType.values.firstWhere(
      (e) => e.name.toUpperCase() == clean,
      orElse: () => PieceType.starCity,
    );
  }
}

class Piece {
  final String id;
  final int? x;
  final int? y;
  final PieceType type;
  final Faction faction;
  final String? tetheredToId;
  final bool isAnchored;

  Piece({
    required this.id,
    this.x,
    this.y,
    required this.type,
    required this.faction,
    this.tetheredToId,
    this.isAnchored = false,
  });

  factory Piece.fromMap(Map<String, dynamic> map) {
    return Piece(
      id: map['id'],
      x: map['x'],
      y: map['y'],
      type: PieceType.fromString(map['type']),
      faction: Faction.fromString(map['faction']),
      tetheredToId: map['tether_id'],
      isAnchored: map['is_anchored'] ?? false,
    );
  }

  Piece copyWith({int? x, int? y, String? tetheredToId, bool? isAnchored}) {
    return Piece(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type,
      faction: faction,
      tetheredToId: tetheredToId ?? this.tetheredToId,
      isAnchored: isAnchored ?? this.isAnchored,
    );
  }
}

class TurnState {
  final int turnNumber;
  final List<Piece> pieces;

  TurnState({required this.turnNumber, required this.pieces});

  factory TurnState.fromMap(Map<String, dynamic> map) {
    return TurnState(
      turnNumber: map['turn_number'],
      pieces: (map['state'] as List? ?? [])
          .map((p) => Piece.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlannedAction {
  final math.Point<int> target;
  final String? tetherId;

  PlannedAction({required this.target, this.tetherId});

  PlannedAction copyWith({math.Point<int>? target, String? tetherId}) {
    return PlannedAction(
      target: target ?? this.target,
      tetherId: tetherId ?? this.tetherId,
    );
  }
}

class TurnEvent {
  final String type;
  final int replayStep;
  final Map<String, dynamic> data;

  TurnEvent({
    required this.type,
    required this.replayStep,
    required this.data,
  });

  factory TurnEvent.fromMap(Map<String, dynamic> map) {
    return TurnEvent(
      type: map['type'] as String,
      replayStep: map['replay_step'] as int? ?? 0,
      data: map,
    );
  }
}

class TurnEventList {
  final int turnNumber;
  final List<TurnEvent> events;

  TurnEventList({required this.turnNumber, required this.events});

  factory TurnEventList.fromMap(Map<String, dynamic> map) {
    return TurnEventList(
      turnNumber: map['turn_number'],
      events: (map['events'] as List? ?? [])
          .map((e) => TurnEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
