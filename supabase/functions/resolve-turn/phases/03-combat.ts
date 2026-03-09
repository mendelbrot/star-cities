import { BombardEvent, BattleCollisionEvent, Faction, PieceType, Coordinate, PlannedAction, Player } from "../../_shared/types.ts";
import { getTorusDistance, getAdjacentCoordinates } from "../../_shared/map.ts";
import { TurnContext } from "../context.ts";
import { BOMBARD_RANGE, BOMBARD_STRENGTH, UNIT_STRENGTH, UNIT_MOVEMENT, SUPPORT_STRENGTH_FACTOR, BOMBARD_SUPPORT_STRENGTH, TETHER_RANGE } from "../constants.ts";
import { weightedRoll } from "../utils.ts";

interface ValidatedMove {
  piece_id: string;
  from: Coordinate;
  to: Coordinate;
  faction: Faction;
  applied: boolean;
}

export function resolveCombat(
  context: TurnContext,
  plannedActions: { player_id: string; actions: PlannedAction[] }[]
) {
  const { params, pieceMap, coordinateMap, pieceContexts, players } = context;
  const size = params.grid_size;

  // 3a. Resolve BOMBARD actions
  context.currentStep = 2;
  const bombardEventsMap = new Map<string, BombardEvent>();
  const bombardmentsByCoord = new Map<string, { piece_id: string; piece_type: PieceType; faction: Faction }[]>();

  for (const playerActionRow of plannedActions) {
    const player = players.find((p: Player) => p.id === playerActionRow.player_id);
    if (!player) continue;

    for (const action of playerActionRow.actions) {
      if (action.type === "BOMBARD_ACT") {
        const attacker = pieceMap.get(action.piece_id);
        if (!attacker || attacker.type !== "ECLIPSE" || attacker.faction !== player.faction || attacker.is_in_tray) continue;

        const target = pieceMap.get(action.target_id);
        if (!target || target.faction === player.faction || target.is_in_tray) continue;

        const dist = getTorusDistance(attacker as Coordinate, target as Coordinate, size);
        if (dist > BOMBARD_RANGE) continue;

        const targetKey = `${target.x},${target.y}`;
        const existing = bombardmentsByCoord.get(targetKey) || [];
        existing.push({ piece_id: attacker.id, piece_type: attacker.type, faction: attacker.faction });
        bombardmentsByCoord.set(targetKey, existing);

        let event = bombardEventsMap.get(target.id);
        if (!event) {
          event = {
            type: "BOMBARD",
            coord: { x: target.x!, y: target.y! },
            attacking_pieces: [],
            target: { piece_id: target.id, piece_type: target.type, faction: target.faction },
            attack_strength: 0,
            target_strength: UNIT_STRENGTH[target.type],
            is_destroyed: false,
          };
          bombardEventsMap.set(target.id, event);
        }

        event.attacking_pieces.push({ piece_id: attacker.id, piece_type: attacker.type, faction: attacker.faction });
        event.attack_strength += BOMBARD_STRENGTH;
      }
    }
  }

  for (const event of bombardEventsMap.values()) {
    event.is_destroyed = weightedRoll([
      { label: true, weight: event.attack_strength },
      { label: false, weight: event.target_strength },
    ]);
    context.addEvent(event);

    const target = pieceMap.get(event.target.piece_id);
    if (target && event.is_destroyed) {
      context.addEvent({
        type: "SHIP_DESTROYED_IN_BOMBARDMENT",
        piece_id: target.id,
        piece_type: target.type,
        faction: target.faction,
      });
      context.removePiece(target.id);
    }
  }
  context.captureSnapshot();

  // 3b. Resolve MOVE_ACT actions
  context.currentStep = 3;
  const validatedMoves: ValidatedMove[] = [];
  const moveTargetCount = new Map<string, number>();

  for (const playerActionRow of plannedActions) {
    const player = players.find((p: Player) => p.id === playerActionRow.player_id);
    if (!player) continue;

    for (const action of playerActionRow.actions) {
      if (action.type === "MOVE_ACT") {
        const piece = pieceMap.get(action.piece_id);
        if (!piece || piece.faction !== player.faction || piece.is_in_tray) continue;
        if (getTorusDistance(piece as Coordinate, action.to, size) > UNIT_MOVEMENT[piece.type]) continue;
        if (context.isStarAt(action.to)) continue;
        
        const ctx = pieceContexts.get(piece.id);
        if (ctx?.wasJustPlaced) continue;
        if (piece.type === "STAR_CITY" && (piece.is_anchored || ctx?.wasJustDeanchored)) continue;

        const occupantId = coordinateMap.get(`${action.to.x},${action.to.y}`);
        if (occupantId) {
          const occupant = pieceMap.get(occupantId);
          if (occupant && occupant.faction === player.faction && pieceContexts.get(occupantId)?.wasJustPlaced) continue;
        }

        if ((piece.type === "ECLIPSE" || piece.type === "PARALLAX") && piece.tether_id) {
          const city = pieceMap.get(piece.tether_id);
          if (!city || getTorusDistance(action.to, city as Coordinate, size) > TETHER_RANGE) continue;
        }

        validatedMoves.push({
          piece_id: piece.id,
          from: { x: piece.x!, y: piece.y! },
          to: action.to,
          faction: player.faction as Faction,
          applied: false,
        });
        const targetKey = `${action.to.x},${action.to.y}`;
        moveTargetCount.set(targetKey, (moveTargetCount.get(targetKey) || 0) + 1);
      }
    }
  }

  const applyNonConflictingMoves = (moves: ValidatedMove[]) => {
    let changed = true;
    while (changed) {
      changed = false;
      for (const move of moves) {
        if (move.applied) continue;

        const piece = pieceMap.get(move.piece_id);
        if (!piece) {
          move.applied = true;
          continue;
        }

        const targetKey = `${move.to.x},${move.to.y}`;
        const targetCount = moveTargetCount.get(targetKey) || 0;

        if (targetCount === 1 && !coordinateMap.has(targetKey)) {
          context.updatePiecePosition(piece.id, move.to);
          context.addEvent({ type: "MOVE", faction: move.faction, piece_id: move.piece_id, from: move.from, to: move.to });
          move.applied = true;
          changed = true;
        }
      }
    }
  };

  const factionTargetKeys = new Set<string>();
  const invalidMoveIndices = new Set<number>();
  for (let i = 0; i < validatedMoves.length; i++) {
    const m = validatedMoves[i];
    const key = `${m.faction}|${m.to.x},${m.to.y}`;
    if (factionTargetKeys.has(key)) {
      for (let j = 0; j < i; j++) {
        if (`${validatedMoves[j].faction}|${validatedMoves[j].to.x},${validatedMoves[j].to.y}` === key) invalidMoveIndices.add(j);
      }
      invalidMoveIndices.add(i);
    }
    factionTargetKeys.add(key);
  }
  const finalValidatedMoves = validatedMoves.filter((_, i) => !invalidMoveIndices.has(i));

  applyNonConflictingMoves(finalValidatedMoves);
  context.captureSnapshot();

  // 3c. Identify Battles and Collisions
  const unappliedMovesByCoord = new Map<string, ValidatedMove[]>();
  for (const m of finalValidatedMoves) {
    if (!m.applied) {
      const key = `${m.to.x},${m.to.y}`;
      const list = unappliedMovesByCoord.get(key) || [];
      list.push(m);
      unappliedMovesByCoord.set(key, list);
    }
  }

  const battleCoords = new Set<string>();
  for (const [coordKey, moves] of unappliedMovesByCoord) {
    const occupantId = coordinateMap.get(coordKey);
    const occupant = occupantId ? pieceMap.get(occupantId) : null;
    
    const factions = new Set<Faction>();
    moves.forEach((m: ValidatedMove) => factions.add(m.faction));
    if (occupant) factions.add(occupant.faction);

    if (factions.size > 1) {
      battleCoords.add(coordKey);
    }
  }

  // 3d. Resolve Battles (Weighted Probability)
  context.currentStep = 4;
  const battleEvents: BattleCollisionEvent[] = [];
  for (const coordKey of battleCoords) {
    const [x, y] = coordKey.split(',').map(Number);
    const enteringCandidates = unappliedMovesByCoord.get(coordKey) || [];
    const occupantId = coordinateMap.get(coordKey);
    const occupant = occupantId ? pieceMap.get(occupantId) : null;

    const entering = occupant 
      ? enteringCandidates.filter((m: ValidatedMove) => m.faction !== occupant.faction)
      : enteringCandidates;

    if (entering.length === 0) continue;

    const battle: BattleCollisionEvent = {
      type: "BATTLE_COLLISION",
      coord: { x, y },
      entering_participants: entering.map((m: ValidatedMove) => {
        const p = pieceMap.get(m.piece_id)!;
        return { piece_id: p.id, piece_type: p.type, faction: p.faction };
      }),
      defending_participant: occupant ? { piece_id: occupant.id, piece_type: occupant.type, faction: occupant.faction } : null,
      supporting_participants: [],
      supporting_bombardments: bombardmentsByCoord.get(coordKey) || [],
      calculated_strengths: [],
      winning_faction: "BLUE",
      result: "DESTROY",
    };

    const adj = getAdjacentCoordinates({ x, y }, size);
    for (const a of adj) {
      const sId = coordinateMap.get(`${a.x},${a.y}`);
      if (sId && sId !== occupantId) {
        const p = pieceMap.get(sId)!;
        battle.supporting_participants.push({ piece_id: p.id, piece_type: p.type, faction: p.faction });
      }
    }

    const factions = new Set<Faction>();
    entering.forEach((m: ValidatedMove) => factions.add(m.faction));
    if (occupant) factions.add(occupant.faction);

    const weights = new Map<Faction, number>();
    for (const f of factions) {
      let w = 0;
      entering.filter((m: ValidatedMove) => m.faction === f).forEach((m: ValidatedMove) => w += UNIT_STRENGTH[pieceMap.get(m.piece_id)!.type]);
      if (occupant && occupant.faction === f) w += UNIT_STRENGTH[occupant.type];
      battle.supporting_participants.filter((p: { faction: Faction; piece_type: PieceType }) => p.faction === f).forEach((p: { piece_type: PieceType }) => w += SUPPORT_STRENGTH_FACTOR * UNIT_STRENGTH[p.piece_type]);
      battle.supporting_bombardments.filter((p: { faction: Faction }) => p.faction === f).forEach((_p: { piece_id: string }) => w += BOMBARD_SUPPORT_STRENGTH);
      weights.set(f, w);
      battle.calculated_strengths.push({ faction: f, strength: w });
    }

    const winner = weightedRoll(Array.from(weights.entries()).map(([f, w]) => ({ label: f, weight: w })));
    battle.winning_faction = winner;
    battle.result = (occupant && occupant.type === "STAR_CITY" && occupant.faction !== winner) ? "CAPTURE" : "DESTROY";
    context.addEvent(battle);
    battleEvents.push(battle);
  }

  // 3e. Handle Piece Destruction
  const piecesToDestroy = new Set<string>();
  for (const b of battleEvents) {
    const all = [...b.entering_participants, ...b.supporting_participants, ...(b.defending_participant ? [b.defending_participant] : [])];
    for (const p of all) if (p.piece_type === "NEUTRINO") pieceMap.get(p.piece_id)!.is_visible = true;
    
    for (const p of b.entering_participants) if (p.faction !== b.winning_faction) piecesToDestroy.add(p.piece_id);
    
    if (b.result === "DESTROY" && b.defending_participant && b.defending_participant.faction !== b.winning_faction) {
      piecesToDestroy.add(b.defending_participant.piece_id);
    }
  }

  for (const id of piecesToDestroy) {
    const p = pieceMap.get(id);
    if (p) {
      context.addEvent({ type: "SHIP_DESTROYED_IN_BATTLE", piece_id: p.id, piece_type: p.type, faction: p.faction });
      context.removePiece(id);
    }
  }
  context.captureSnapshot();

  // 3f. Apply Victor Moves and Capture Cities
  context.currentStep = 5;
  for (const b of battleEvents) {
    const winningMove = finalValidatedMoves.find((m: ValidatedMove) => 
      !m.applied && 
      m.faction === b.winning_faction && 
      m.to.x === b.coord.x && 
      m.to.y === b.coord.y
    );

    if (winningMove) {
      if (b.result === "DESTROY") {
        const p = pieceMap.get(winningMove.piece_id);
        if (p) {
          context.updatePiecePosition(p.id, winningMove.to);
          context.addEvent({ type: "MOVE", faction: winningMove.faction, piece_id: winningMove.piece_id, from: winningMove.from, to: winningMove.to });
        }
      }
      winningMove.applied = true;
    }

    const loserMoves = finalValidatedMoves.filter((m: ValidatedMove) => 
      !m.applied && 
      m.to.x === b.coord.x && 
      m.to.y === b.coord.y
    );
    for (const m of loserMoves) m.applied = true;
  }

  for (const b of battleEvents) {
    if (b.result === "CAPTURE" && b.defending_participant) {
      const city = pieceMap.get(b.defending_participant.piece_id);
      if (city) {
        const oldF = city.faction;
        const newF = b.winning_faction;
        context.addEvent({ type: "CITY_CAPTURED", city_id: city.id, from_faction: oldF, to_faction: newF });
        
        // Transfer faction in maps
        const oldList = context.factionPlacedPiecesMap.get(oldF) || [];
        context.factionPlacedPiecesMap.set(oldF, oldList.filter((id: string) => id !== city.id));
        context.factionPlacedPiecesMap.get(newF)?.push(city.id);
        city.faction = newF;
        
        // Cities keep their anchored status but lose tethers upon capture
        context.handleTetherLoss(city.id);
      }
    }
  }

  // 3g. Final Movement Application
  applyNonConflictingMoves(finalValidatedMoves);
  context.captureSnapshot();
}
