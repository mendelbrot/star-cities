import 'dart:math' as math;
import 'package:star_cities/shared/models/faction.dart';
import 'package:star_cities/features/game/models/game_models.dart';

sealed class GameEvent {
  final String type;
  final int replayStep;

  const GameEvent(this.type, this.replayStep);

  factory GameEvent.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    final replayStep = map['replay_step'] as int? ?? 0;

    switch (type) {
      case 'MOVE':
        return MoveEvent.fromMap(map, replayStep);
      case 'TETHER':
        return TetherEvent.fromMap(map, replayStep);
      case 'ANCHOR':
        return AnchorEvent.fromMap(map, replayStep);
      case 'PLACE':
        return PlaceEvent.fromMap(map, replayStep);
      case 'BOMBARD':
        return BombardEvent.fromMap(map, replayStep);
      case 'SHIP_LOST_TETHER':
        return ShipLostTetherEvent.fromMap(map, replayStep);
      case 'BATTLE_COLLISION':
        return BattleCollisionEvent.fromMap(map, replayStep);
      case 'PIECE_ACQUIRED':
        return PieceAcquiredEvent.fromMap(map, replayStep);
      case 'CITY_CAPTURED':
        return CityCapturedEvent.fromMap(map, replayStep);
      case 'SHIP_DESTROYED_IN_BATTLE':
        return ShipDestroyedInBattleEvent.fromMap(map, replayStep);
      case 'SHIP_DESTROYED_IN_BOMBARDMENT':
        return ShipDestroyedInBombardmentEvent.fromMap(map, replayStep);
      case 'FACTION_ELIMINATED':
        return FactionEliminatedEvent.fromMap(map, replayStep);
      case 'GAME_OVER':
        return GameOverEvent.fromMap(map, replayStep);
      default:
        return UnknownEvent(type, replayStep, map);
    }
  }
}

class MoveEvent extends GameEvent {
  final Faction faction;
  final String pieceId;
  final math.Point<int> from;
  final math.Point<int> to;

  const MoveEvent({
    required this.faction,
    required this.pieceId,
    required this.from,
    required this.to,
    required int replayStep,
  }) : super('MOVE', replayStep);

  factory MoveEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return MoveEvent(
      faction: Faction.fromString(map['faction']),
      pieceId: map['piece_id'],
      from: math.Point(map['from']['x'], map['from']['y']),
      to: math.Point(map['to']['x'], map['to']['y']),
      replayStep: replayStep,
    );
  }
}

class TetherEvent extends GameEvent {
  final Faction faction;
  final String shipId;
  final String cityId;

  const TetherEvent({
    required this.faction,
    required this.shipId,
    required this.cityId,
    required int replayStep,
  }) : super('TETHER', replayStep);

  factory TetherEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return TetherEvent(
      faction: Faction.fromString(map['faction']),
      shipId: map['ship_id'],
      cityId: map['city_id'],
      replayStep: replayStep,
    );
  }
}

class AnchorEvent extends GameEvent {
  final Faction faction;
  final String pieceId;
  final bool isAnchored;

  const AnchorEvent({
    required this.faction,
    required this.pieceId,
    required this.isAnchored,
    required int replayStep,
  }) : super('ANCHOR', replayStep);

  factory AnchorEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return AnchorEvent(
      faction: Faction.fromString(map['faction']),
      pieceId: map['piece_id'],
      isAnchored: map['is_anchored'],
      replayStep: replayStep,
    );
  }
}

class PlaceEvent extends GameEvent {
  final Faction faction;
  final String trayPieceId;
  final String? cityId;
  final math.Point<int> target;

  const PlaceEvent({
    required this.faction,
    required this.trayPieceId,
    this.cityId,
    required this.target,
    required int replayStep,
  }) : super('PLACE', replayStep);

  factory PlaceEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return PlaceEvent(
      faction: Faction.fromString(map['faction']),
      trayPieceId: map['tray_piece_id'],
      cityId: map['city_id'],
      target: math.Point(map['target']['x'], map['target']['y']),
      replayStep: replayStep,
    );
  }
}

class Participant {
  final String pieceId;
  final PieceType pieceType;
  final Faction faction;

  Participant({required this.pieceId, required this.pieceType, required this.faction});

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      pieceId: map['piece_id'],
      pieceType: PieceType.fromString(map['piece_type']),
      faction: Faction.fromString(map['faction']),
    );
  }
}

class BombardEvent extends GameEvent {
  final math.Point<int> coord;
  final List<Participant> attackingPieces;
  final Participant target;
  final double attackStrength;
  final double targetStrength;
  final bool isDestroyed;

  const BombardEvent({
    required this.coord,
    required this.attackingPieces,
    required this.target,
    required this.attackStrength,
    required this.targetStrength,
    required this.isDestroyed,
    required int replayStep,
  }) : super('BOMBARD', replayStep);

  factory BombardEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return BombardEvent(
      coord: math.Point(map['coord']['x'], map['coord']['y']),
      attackingPieces: (map['attacking_pieces'] as List).map((p) => Participant.fromMap(p)).toList(),
      target: Participant.fromMap(map['target']),
      attackStrength: (map['attack_strength'] as num).toDouble(),
      targetStrength: (map['target_strength'] as num).toDouble(),
      isDestroyed: map['is_destroyed'],
      replayStep: replayStep,
    );
  }
}

class ShipLostTetherEvent extends GameEvent {
  final Faction faction;
  final String pieceId;

  const ShipLostTetherEvent({
    required this.faction,
    required this.pieceId,
    required int replayStep,
  }) : super('SHIP_LOST_TETHER', replayStep);

  factory ShipLostTetherEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return ShipLostTetherEvent(
      faction: Faction.fromString(map['faction']),
      pieceId: map['piece_id'],
      replayStep: replayStep,
    );
  }
}

class FactionStrength {
  final Faction faction;
  final double strength;

  FactionStrength({required this.faction, required this.strength});

  factory FactionStrength.fromMap(Map<String, dynamic> map) {
    return FactionStrength(
      faction: Faction.fromString(map['faction']),
      strength: (map['strength'] as num).toDouble(),
    );
  }
}

class BattleCollisionEvent extends GameEvent {
  final math.Point<int> coord;
  final List<Participant> enteringParticipants;
  final Participant? defendingParticipant;
  final List<Participant> supportingParticipants;
  final List<Participant> supportingBombardments;
  final List<FactionStrength> calculatedStrengths;
  final Faction winningFaction;
  final String result;

  const BattleCollisionEvent({
    required this.coord,
    required this.enteringParticipants,
    this.defendingParticipant,
    required this.supportingParticipants,
    required this.supportingBombardments,
    required this.calculatedStrengths,
    required this.winningFaction,
    required this.result,
    required int replayStep,
  }) : super('BATTLE_COLLISION', replayStep);

  factory BattleCollisionEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return BattleCollisionEvent(
      coord: math.Point(map['coord']['x'], map['coord']['y']),
      enteringParticipants: (map['entering_participants'] as List).map((p) => Participant.fromMap(p)).toList(),
      defendingParticipant: map['defending_participant'] != null ? Participant.fromMap(map['defending_participant']) : null,
      supportingParticipants: (map['supporting_participants'] as List).map((p) => Participant.fromMap(p)).toList(),
      supportingBombardments: (map['supporting_bombardments'] as List).map((p) => Participant.fromMap(p)).toList(),
      calculatedStrengths: (map['calculated_strengths'] as List).map((s) => FactionStrength.fromMap(s)).toList(),
      winningFaction: Faction.fromString(map['winning_faction']),
      result: map['result'],
      replayStep: replayStep,
    );
  }
}

class PieceAcquiredEvent extends GameEvent {
  final Faction faction;
  final PieceType pieceType;
  final String newPieceId;

  const PieceAcquiredEvent({
    required this.faction,
    required this.pieceType,
    required this.newPieceId,
    required int replayStep,
  }) : super('PIECE_ACQUIRED', replayStep);

  factory PieceAcquiredEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return PieceAcquiredEvent(
      faction: Faction.fromString(map['faction']),
      pieceType: PieceType.fromString(map['piece_type']),
      newPieceId: map['new_piece_id'],
      replayStep: replayStep,
    );
  }
}

class CityCapturedEvent extends GameEvent {
  final String cityId;
  final Faction fromFaction;
  final Faction toFaction;

  const CityCapturedEvent({
    required this.cityId,
    required this.fromFaction,
    required this.toFaction,
    required int replayStep,
  }) : super('CITY_CAPTURED', replayStep);

  factory CityCapturedEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return CityCapturedEvent(
      cityId: map['city_id'],
      fromFaction: Faction.fromString(map['from_faction']),
      toFaction: Faction.fromString(map['to_faction']),
      replayStep: replayStep,
    );
  }
}

class ShipDestroyedInBattleEvent extends GameEvent {
  final String pieceId;
  final PieceType pieceType;
  final Faction faction;

  const ShipDestroyedInBattleEvent({
    required this.pieceId,
    required this.pieceType,
    required this.faction,
    required int replayStep,
  }) : super('SHIP_DESTROYED_IN_BATTLE', replayStep);

  factory ShipDestroyedInBattleEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return ShipDestroyedInBattleEvent(
      pieceId: map['piece_id'],
      pieceType: PieceType.fromString(map['piece_type']),
      faction: Faction.fromString(map['faction']),
      replayStep: replayStep,
    );
  }
}

class ShipDestroyedInBombardmentEvent extends GameEvent {
  final String pieceId;
  final PieceType pieceType;
  final Faction faction;

  const ShipDestroyedInBombardmentEvent({
    required this.pieceId,
    required this.pieceType,
    required this.faction,
    required int replayStep,
  }) : super('SHIP_DESTROYED_IN_BOMBARDMENT', replayStep);

  factory ShipDestroyedInBombardmentEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return ShipDestroyedInBombardmentEvent(
      pieceId: map['piece_id'],
      pieceType: PieceType.fromString(map['piece_type']),
      faction: Faction.fromString(map['faction']),
      replayStep: replayStep,
    );
  }
}

class FactionEliminatedEvent extends GameEvent {
  final Faction faction;

  const FactionEliminatedEvent({
    required this.faction,
    required int replayStep,
  }) : super('FACTION_ELIMINATED', replayStep);

  factory FactionEliminatedEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return FactionEliminatedEvent(
      faction: Faction.fromString(map['faction']),
      replayStep: replayStep,
    );
  }
}

class GameOverEvent extends GameEvent {
  final Faction? winner;
  final bool didSomeoneWin;

  const GameOverEvent({
    this.winner,
    required this.didSomeoneWin,
    required int replayStep,
  }) : super('GAME_OVER', replayStep);

  factory GameOverEvent.fromMap(Map<String, dynamic> map, int replayStep) {
    return GameOverEvent(
      winner: map['winner'] != null ? Faction.fromString(map['winner']) : null,
      didSomeoneWin: map['did_someone_win'],
      replayStep: replayStep,
    );
  }
}

class PlayerRanking {
  final String playerId;
  final Faction faction;
  final int starCount;

  PlayerRanking({
    required this.playerId,
    required this.faction,
    required this.starCount,
  });

  factory PlayerRanking.fromMap(Map<String, dynamic> map) {
    return PlayerRanking(
      playerId: map['player_id'],
      faction: Faction.fromString(map['faction']),
      starCount: map['star_count'],
    );
  }
}

class TurnEventList {
  final int turnNumber;
  final List<GameEvent> events;
  final Map<int, List<Piece>> snapshots;
  final List<PlayerRanking> playerRanking;

  TurnEventList({
    required this.turnNumber,
    required this.events,
    required this.snapshots,
    required this.playerRanking,
  });

  factory TurnEventList.fromMap(Map<String, dynamic> map) {
    final snapshotsMap = (map['snapshots'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as List).map((p) => Piece.fromMap(p as Map<String, dynamic>)).toList(),
      ),
    ) ?? {};

    return TurnEventList(
      turnNumber: map['turn_number'],
      events: (map['events'] as List? ?? [])
          .map((e) => GameEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      snapshots: snapshotsMap,
      playerRanking: (map['player_ranking'] as List? ?? [])
          .map((r) => PlayerRanking.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UnknownEvent extends GameEvent {
  final Map<String, dynamic> rawData;
  const UnknownEvent(super.type, super.replayStep, this.rawData);
}
