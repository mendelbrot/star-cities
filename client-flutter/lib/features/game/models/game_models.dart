import 'package:flutter/material.dart';
import 'dart:math' as math;

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
}

class Piece {
  final String id;
  final int? x;
  final int? y;
  final PieceType type;
  final Color color; // Keep Color for now as used in existing code
  final String? tetheredToId;
  final bool isAnchored;

  Piece({
    required this.id,
    this.x,
    this.y,
    required this.type,
    required this.color,
    this.tetheredToId,
    this.isAnchored = false,
  });

  Piece copyWith({int? x, int? y, String? tetheredToId, bool? isAnchored}) {
    return Piece(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type,
      color: color,
      tetheredToId: tetheredToId ?? this.tetheredToId,
      isAnchored: isAnchored ?? this.isAnchored,
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
