import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { BombardEvent, Coordinate, Faction, GameEvent, GameParameters, Piece, PieceType, PlannedAction, BattleCollisionEvent } from "../_shared/types.ts";
import { ServerError } from "../_shared/server-error.ts";
import { getAdjacentCoordinates, getTorusDistance, isSameCoordinate } from "../_shared/map.ts";

interface WebhookPayload {
  record: {
    id: string;
    status: string;
    turn_number: number;
  };
}

interface GameRow {
  status: string;
  game_parameters: GameParameters;
  stars: Coordinate[];
}

interface PlayerRow {
  id: string;
  faction: string;
  is_eliminated: boolean;
}

interface TurnStateRow {
  state: Piece[];
}

interface TurnPlannedActionsRow {
  player_id: string;
  actions: PlannedAction[];
}

interface PieceTurnContext {
  wasJustPlaced?: boolean;
  wasJustDeanchored?: boolean;
}

serve(async (req) => {
  try {
    const body: WebhookPayload = await req.json();
    const { record } = body;
    const { id: game_id, status, turn_number } = record;

    if (status !== "RESOLVING") {
      return new Response(null, { status: 200 });
    }

    console.log(`Resolving turn ${turn_number} for game: ${game_id}`);

    await sql.begin(async (sql) => {
      // 1. Fetch Game, Players, Current State, and Planned Actions
      const [game] = await sql<GameRow[]>`
        SELECT status, game_parameters, stars FROM games WHERE id = ${game_id} FOR UPDATE
      `;

      if (!game) {
        throw new ServerError(`Game not found: ${game_id}`, 400);
      }

      if (game.status !== "RESOLVING") {
        throw new ServerError(`Game status changed to ${game.status}.`, 400);
      }

      const players = await sql<PlayerRow[]>`
        SELECT id, faction, is_eliminated FROM players 
        WHERE game_id = ${game_id}
      `;

      const activePlayers = players.filter(p => !p.is_eliminated);

      const [currentStateRow] = await sql<TurnStateRow[]>`
        SELECT state FROM turn_states 
        WHERE game_id = ${game_id} AND turn_number = ${turn_number}
      `;

      if (!currentStateRow) {
        throw new ServerError(`Turn state not found for turn ${turn_number}`, 400);
      }

      const plannedActions = await sql<TurnPlannedActionsRow[]>`
        SELECT player_id, actions FROM turn_planned_actions 
        WHERE game_id = ${game_id} AND turn_number = ${turn_number}
      `;

      // Phase 1: Indexing State
      const params = game.game_parameters;
      const size = params.grid_size;

      // 1a. Copy the state to the working state and reset fields per documentation
      const workingState: Piece[] = currentStateRow.state.map((p) => ({
        ...p,
        is_stunned: false,
        is_visible: p.type === "NEUTRINO" ? false : true,
      }));

      // 1b. Build Indexes
      const pieceMap = new Map<string, Piece>(); // id -> Piece
      const coordinateMap = new Map<string, string>(); // (x,y) -> piece_id
      const factionPlacedPiecesMap = new Map<string, string[]>(); // faction -> list of piece_ids
      const factionTrayMap = new Map<string, string[]>(); // faction -> list of piece_ids
      const tetherMap = new Map<string, string[]>(); // city_id -> list of ship_ids
      const pieceContexts = new Map<string, PieceTurnContext>(); // piece_id -> PieceTurnContext

      // Initialize maps for each faction
      players.forEach((p) => {
        factionPlacedPiecesMap.set(p.faction, []);
        factionTrayMap.set(p.faction, []);
      });

      for (const p of workingState) {
        pieceMap.set(p.id, p);

        if (p.is_in_tray || p.x === null || p.y === null) {
          factionTrayMap.get(p.faction)?.push(p.id);
        } else {
          const key = `${p.x},${p.y}`;
          coordinateMap.set(key, p.id);
          factionPlacedPiecesMap.get(p.faction)?.push(p.id);

          if (p.tether_id) {
            const ships = tetherMap.get(p.tether_id) || [];
            ships.push(p.id);
            tetherMap.set(p.tether_id, ships);
          }
        }
      }

      const events: GameEvent[] = [];

      // Pre-calculate move targets for validation
      const factionMoveTargetsMap = new Map<string, Set<string>>(); 
      for (const row of plannedActions) {
        const player = players.find(p => p.id === row.player_id);
        if (!player) continue;
        const targets = new Set<string>();
        for (const action of row.actions) {
          if (action.type === "MOVE_ACT") {
            targets.add(`${action.to.x},${action.to.y}`);
          }
        }
        factionMoveTargetsMap.set(player.faction, targets);
      }

      const UNIT_STRENGTH: Record<string, number> = {
        STAR_CITY: 8,
        NEUTRINO: 2,
        ECLIPSE: 4,
        PARALLAX: 6,
      };

      const lossCascade = (lost_city_id: string) => {
        const tetheredShips = tetherMap.get(lost_city_id) || [];
        for (const shipId of tetheredShips) {
          const ship = pieceMap.get(shipId);
          if (ship) {
            events.push({
              type: "SHIP_LOST_TETHER",
              faction: ship.faction,
              piece_id: ship.id,
            });

            if (ship.x !== null && ship.y !== null) {
              coordinateMap.delete(`${ship.x},${ship.y}`);
            }
            const factionPlaced = factionPlacedPiecesMap.get(ship.faction) || [];
            factionPlacedPiecesMap.set(ship.faction, factionPlaced.filter((id) => id !== ship.id));

            pieceMap.delete(shipId);
          }
        }
        tetherMap.delete(lost_city_id);
      };

      // Phase 2: Resolve PLACE, TETHER, ANCHOR
      for (const playerActionRow of plannedActions) {
        const player = players.find((p) => p.id === playerActionRow.player_id);
        if (!player) continue;

        for (const action of playerActionRow.actions) {
          if (action.type === "PLACE_ACT") {
            const piece = pieceMap.get(action.tray_piece_id);
            if (!piece || !piece.is_in_tray || piece.faction !== player.faction) continue;

            const isStar = game.stars.some((s) => isSameCoordinate(s, action.target));
            const isOccupied = coordinateMap.has(`${action.target.x},${action.target.y}`);
            const isMoveTarget = factionMoveTargetsMap.get(player.faction)?.has(`${action.target.x},${action.target.y}`);
            if (isStar || isOccupied || isMoveTarget) continue;

            let isNearValidCity = false;
            if (piece.type === "ECLIPSE" || piece.type === "PARALLAX") {
              if (!action.city_id) continue;
              const city = pieceMap.get(action.city_id);
              if (!city || city.type !== "STAR_CITY" || city.faction !== player.faction || !city.is_anchored) continue;
              
              const tetheredCount = tetherMap.get(city.id)?.length || 0;
              if (tetheredCount >= 5) continue;

              const adj = getAdjacentCoordinates(city as Coordinate, size);
              isNearValidCity = adj.some((a) => isSameCoordinate(a, action.target));
            } else {
              const factionCities = (factionPlacedPiecesMap.get(player.faction) || [])
                .map(id => pieceMap.get(id)!)
                .filter(p => p.type === "STAR_CITY");
              
              isNearValidCity = factionCities.some(city => {
                const adj = getAdjacentCoordinates(city as Coordinate, size);
                return adj.some(a => isSameCoordinate(a, action.target));
              });
            }

            if (!isNearValidCity) continue;

            piece.x = action.target.x;
            piece.y = action.target.y;
            piece.is_in_tray = false;
            if (piece.type === "ECLIPSE" || piece.type === "PARALLAX") {
              piece.tether_id = action.city_id;
              const ships = tetherMap.get(action.city_id!) || [];
              ships.push(piece.id);
              tetherMap.set(action.city_id!, ships);
            }

            coordinateMap.set(`${piece.x},${piece.y}`, piece.id);
            const tray = factionTrayMap.get(player.faction)!;
            const idx = tray.indexOf(piece.id);
            if (idx !== -1) tray.splice(idx, 1);
            factionPlacedPiecesMap.get(player.faction)?.push(piece.id);
            pieceContexts.set(piece.id, { wasJustPlaced: true });

            events.push({
              type: "PLACE",
              faction: player.faction as Faction,
              tray_piece_id: action.tray_piece_id,
              city_id: action.city_id,
              target: action.target,
            });
          } 
          else if (action.type === "TETHER_ACT") {
            const ship = pieceMap.get(action.ship_id);
            if (!ship || ship.is_in_tray || ship.faction !== player.faction || ship.is_stunned) continue;
            if (ship.type !== "ECLIPSE" && ship.type !== "PARALLAX") continue;

            const city = pieceMap.get(action.city_id);
            if (!city || city.type !== "STAR_CITY" || city.faction !== player.faction || !city.is_anchored) continue;

            const tetheredCount = tetherMap.get(city.id)?.length || 0;
            if (tetheredCount >= 5) continue;

            const dist = getTorusDistance(ship as Coordinate, city as Coordinate, size);
            if (dist > 2) continue;

            if (ship.tether_id) {
              const oldShips = tetherMap.get(ship.tether_id) || [];
              tetherMap.set(ship.tether_id, oldShips.filter(id => id !== ship.id));
            }

            ship.tether_id = action.city_id;
            const ships = tetherMap.get(action.city_id) || [];
            ships.push(ship.id);
            tetherMap.set(action.city_id, ships);

            events.push({
              type: "TETHER",
              faction: player.faction as Faction,
              ship_id: action.ship_id,
              city_id: action.city_id,
            });
          }
          else if (action.type === "ANCHOR_ACT") {
            const city = pieceMap.get(action.piece_id);
            if (!city || city.type !== "STAR_CITY" || city.is_in_tray || city.faction !== player.faction || city.is_stunned) continue;

            if (action.is_anchored) {
              const adj = getAdjacentCoordinates(city as Coordinate, size);
              const isNearStar = adj.some(a => game.stars.some(s => isSameCoordinate(s, a)));
              if (!isNearStar) continue;
            } else {
              const tetheredCount = tetherMap.get(city.id)?.length || 0;
              if (tetheredCount > 0) continue;
            }

            const wasAnchored = city.is_anchored;
            city.is_anchored = action.is_anchored;
            if (wasAnchored && !action.is_anchored) {
              pieceContexts.set(city.id, { wasJustDeanchored: true });
            }

            events.push({
              type: "ANCHOR",
              faction: player.faction as Faction,
              piece_id: action.piece_id,
              is_anchored: action.is_anchored,
            });
          }
        }
      }

      // Phase 3: Resolve BOMBARD actions
      const bombardEventsMap = new Map<string, BombardEvent>();
      const bombardmentsByCoord = new Map<string, { piece_id: string; piece_type: PieceType; faction: Faction }[]>();

      for (const playerActionRow of plannedActions) {
        const player = players.find((p) => p.id === playerActionRow.player_id);
        if (!player) continue;

        for (const action of playerActionRow.actions) {
          if (action.type === "BOMBARD_ACT") {
            const attacker = pieceMap.get(action.piece_id);
            if (!attacker || attacker.type !== "ECLIPSE" || attacker.faction !== player.faction || attacker.is_stunned || attacker.is_in_tray) continue;

            const target = pieceMap.get(action.target_id);
            if (!target || target.faction === player.faction || target.is_in_tray) continue;

            const dist = getTorusDistance(attacker as Coordinate, target as Coordinate, size);
            if (dist > 2) continue;

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
            event.attack_strength += 2;
          }
        }
      }

      for (const event of bombardEventsMap.values()) {
        const totalStrength = event.attack_strength + event.target_strength;
        const roll = Math.random() * totalStrength;
        event.is_destroyed = roll < event.attack_strength;
        events.push(event);

        const target = pieceMap.get(event.target.piece_id);
        if (target) {
          target.is_stunned = true;
          if (event.is_destroyed) {
            events.push({
              type: "SHIP_DESTROYED_IN_BOMBARDMENT",
              piece_id: target.id,
              piece_type: target.type,
              faction: target.faction,
            });
            if (target.x !== null && target.y !== null) coordinateMap.delete(`${target.x},${target.y}`);
            const factionPlaced = factionPlacedPiecesMap.get(target.faction) || [];
            factionPlacedPiecesMap.set(target.faction, factionPlaced.filter((id) => id !== target.id));
            if (target.type === "STAR_CITY") lossCascade(target.id);
            else if (target.tether_id) {
              const ships = tetherMap.get(target.tether_id) || [];
              tetherMap.set(target.tether_id, ships.filter((id) => id !== target.id));
            }
            pieceMap.delete(target.id);
          }
        }
      }

      // Phase 4: Resolve MOVE_ACT actions
      const UNIT_MOVEMENT: Record<string, number> = { STAR_CITY: 1, NEUTRINO: 1, ECLIPSE: 1, PARALLAX: 2 };

      interface ValidatedMove {
        piece_id: string;
        from: Coordinate;
        to: Coordinate;
        faction: Faction;
        applied: boolean;
      }

      const validatedMoves: ValidatedMove[] = [];
      const moveTargetCount = new Map<string, number>();

      for (const playerActionRow of plannedActions) {
        const player = players.find((p) => p.id === playerActionRow.player_id);
        if (!player) continue;

        for (const action of playerActionRow.actions) {
          if (action.type === "MOVE_ACT") {
            const piece = pieceMap.get(action.piece_id);
            if (!piece || piece.faction !== player.faction || piece.is_stunned || piece.is_in_tray) continue;
            if (getTorusDistance(piece as Coordinate, action.to, size) > UNIT_MOVEMENT[piece.type]) continue;
            if (game.stars.some((s) => isSameCoordinate(s, action.to))) continue;
            
            const context = pieceContexts.get(piece.id);
            if (context?.wasJustPlaced) continue;
            if (piece.type === "STAR_CITY" && (piece.is_anchored || context?.wasJustDeanchored)) continue;

            const occupantId = coordinateMap.get(`${action.to.x},${action.to.y}`);
            if (occupantId) {
              const occupant = pieceMap.get(occupantId);
              if (occupant && occupant.faction === player.faction && pieceContexts.get(occupantId)?.wasJustPlaced) continue;
            }

            if ((piece.type === "ECLIPSE" || piece.type === "PARALLAX") && piece.tether_id) {
              const city = pieceMap.get(piece.tether_id);
              if (!city || getTorusDistance(action.to, city as Coordinate, size) > 2) continue;
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

      let movesAppliedThisLoop = true;
      while (movesAppliedThisLoop) {
        movesAppliedThisLoop = false;
        for (const move of finalValidatedMoves) {
          const targetKey = `${move.to.x},${move.to.y}`;
          if (!move.applied && moveTargetCount.get(targetKey) === 1 && !coordinateMap.has(targetKey)) {
            const piece = pieceMap.get(move.piece_id);
            if (piece) {
              coordinateMap.delete(`${move.from.x},${move.from.y}`);
              piece.x = move.to.x;
              piece.y = move.to.y;
              coordinateMap.set(targetKey, piece.id);
              events.push({ type: "MOVE", faction: move.faction, piece_id: move.piece_id, from: move.from, to: move.to });
              move.applied = true;
              movesAppliedThisLoop = true;
            } else move.applied = true;
          }
        }
      }

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
        if (moves.length > 1 || coordinateMap.has(coordKey)) battleCoords.add(coordKey);
      }

      const battleEvents: BattleCollisionEvent[] = [];
      for (const coordKey of battleCoords) {
        const [x, y] = coordKey.split(',').map(Number);
        const entering = unappliedMovesByCoord.get(coordKey) || [];
        const defenderId = coordinateMap.get(coordKey);
        const defender = defenderId ? pieceMap.get(defenderId) : null;

        const battle: BattleCollisionEvent = {
          type: "BATTLE_COLLISION",
          coord: { x, y },
          entering_participants: entering.map(m => {
            const p = pieceMap.get(m.piece_id)!;
            return { piece_id: p.id, piece_type: p.type, faction: p.faction };
          }),
          defending_participant: defender ? { piece_id: defender.id, piece_type: defender.type, faction: defender.faction } : null,
          supporting_participants: [],
          supporting_bombardments: bombardmentsByCoord.get(coordKey) || [],
          calculated_strengths: [],
          winning_faction: "BLUE",
          result: "DESTROY",
        };

        const adj = getAdjacentCoordinates({ x, y }, size);
        for (const a of adj) {
          const sId = coordinateMap.get(`${a.x},${a.y}`);
          if (sId && sId !== defenderId) {
            const p = pieceMap.get(sId)!;
            battle.supporting_participants.push({ piece_id: p.id, piece_type: p.type, faction: p.faction });
          }
        }

        const factions = new Set<Faction>();
        entering.forEach(m => factions.add(m.faction));
        if (defender) factions.add(defender.faction);

        const weights = new Map<Faction, number>();
        for (const f of factions) {
          let w = 0;
          entering.filter(m => m.faction === f).forEach(m => w += UNIT_STRENGTH[pieceMap.get(m.piece_id)!.type]);
          if (defender && defender.faction === f) w += UNIT_STRENGTH[defender.type];
          battle.supporting_participants.filter(p => p.faction === f).forEach(p => w += 0.5 * UNIT_STRENGTH[p.piece_type]);
          battle.supporting_bombardments.filter(p => p.faction === f).forEach(p => w += 1.0);
          weights.set(f, w);
          battle.calculated_strengths.push({ faction: f, strength: w });
        }

        const totalW = Array.from(weights.values()).reduce((a, b) => a + b, 0);
        let roll = Math.random() * (totalW || 1);
        let winner: Faction = Array.from(weights.keys())[0];
        for (const [f, w] of weights.entries()) {
          if (roll < w) { winner = f; break; }
          roll -= w;
        }
        battle.winning_faction = winner;
        battle.result = (defender && defender.type === "STAR_CITY" && defender.faction !== winner) ? "CAPTURE" : "DESTROY";
        events.push(battle);
        battleEvents.push(battle);
      }

      const piecesToDestroy = new Set<string>();
      for (const b of battleEvents) {
        const all = [...b.entering_participants, ...b.supporting_participants, ...(b.defending_participant ? [b.defending_participant] : [])];
        for (const p of all) if (p.piece_type === "NEUTRINO") pieceMap.get(p.piece_id)!.is_visible = true;
        for (const p of b.entering_participants) if (p.faction !== b.winning_faction) piecesToDestroy.add(p.piece_id);
        if (b.result === "DESTROY" && b.defending_participant && b.defending_participant.faction !== b.winning_faction) piecesToDestroy.add(b.defending_participant.piece_id);
      }

      for (const id of piecesToDestroy) {
        const p = pieceMap.get(id);
        if (p) {
          events.push({ type: "SHIP_DESTROYED_IN_BATTLE", piece_id: p.id, piece_type: p.type, faction: p.faction });
          if (p.x !== null && p.y !== null) coordinateMap.delete(`${p.x},${p.y}`);
          const factionPlaced = factionPlacedPiecesMap.get(p.faction) || [];
          factionPlacedPiecesMap.set(p.faction, factionPlaced.filter(pid => pid !== p.id));
          if (p.type === "STAR_CITY") lossCascade(p.id);
          else if (p.tether_id) {
            const ships = tetherMap.get(p.tether_id) || [];
            tetherMap.set(p.tether_id, ships.filter(sid => sid !== p.id));
          }
          pieceMap.delete(id);
        }
      }

      for (const b of battleEvents) {
        if (b.result === "CAPTURE" && b.defending_participant) {
          const city = pieceMap.get(b.defending_participant.piece_id);
          if (city) {
            const oldF = city.faction;
            const newF = b.winning_faction;
            events.push({ type: "CITY_CAPTURED", city_id: city.id, from_faction: oldF, to_faction: newF });
            const oldList = factionPlacedPiecesMap.get(oldF) || [];
            factionPlacedPiecesMap.set(oldF, oldList.filter(id => id !== city.id));
            factionPlacedPiecesMap.get(newF)?.push(city.id);
            city.faction = newF;
            lossCascade(city.id);
          }
        }
      }

      const remMoves = finalValidatedMoves.filter(m => !m.applied && pieceMap.has(m.piece_id));
      movesAppliedThisLoop = true;
      while (movesAppliedThisLoop) {
        movesAppliedThisLoop = false;
        for (const move of remMoves) {
          const tKey = `${move.to.x},${move.to.y}`;
          if (!move.applied && !coordinateMap.has(tKey)) {
            const p = pieceMap.get(move.piece_id);
            if (p) {
              coordinateMap.delete(`${move.from.x},${move.from.y}`);
              p.x = move.to.x;
              p.y = move.to.y;
              coordinateMap.set(tKey, p.id);
              events.push({ type: "MOVE", faction: move.faction, piece_id: move.piece_id, from: move.from, to: move.to });
              move.applied = true;
              movesAppliedThisLoop = true;
            } else move.applied = true;
          }
        }
      }

      // Phase 5: Win/Elimination
      const eliminated = [];
      for (const p of activePlayers) {
        const faction = p.faction as Faction;
        if ((factionPlacedPiecesMap.get(faction) || []).map(id => pieceMap.get(id)!).filter(p => p.type === "STAR_CITY").length === 0) eliminated.push(faction);
      }

      for (const f of eliminated) {
        events.push({ type: "FACTION_ELIMINATED", faction: f });
        const placed = factionPlacedPiecesMap.get(f) || [];
        for (const id of placed) {
          const p = pieceMap.get(id);
          if (p && p.x !== null && p.y !== null) coordinateMap.delete(`${p.x},${p.y}`);
          pieceMap.delete(id);
        }
        factionPlacedPiecesMap.set(f, []);
        const tray = factionTrayMap.get(f) || [];
        for (const id of tray) pieceMap.delete(id);
        factionTrayMap.set(f, []);
        await sql`UPDATE players SET is_eliminated = TRUE, eliminated_on_turn = ${turn_number} WHERE game_id = ${game_id} AND faction = ${f}`;
      }

      const remaining = activePlayers.filter(p => !eliminated.includes(p.faction as Faction));
      let winnerF: Faction | null = null;
      if (remaining.length === 1) winnerF = remaining[0].faction as Faction;
      else if (remaining.length > 0) {
        const counts = new Map<Faction, number>();
        for (const p of remaining) {
          const f = p.faction as Faction;
          const stars = new Set<string>();
          (factionPlacedPiecesMap.get(f) || []).map(id => pieceMap.get(id)!).filter(p => p.type === "STAR_CITY" && p.is_anchored).forEach(city => {
            getAdjacentCoordinates(city as Coordinate, size).forEach(a => { if (game.stars.some(s => isSameCoordinate(s, a))) stars.add(`${a.x},${a.y}`); });
          });
          counts.set(f, stars.size);
        }
        const sorted = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
        if (sorted.length > 0 && sorted[0][1] >= 3 && (sorted.length === 1 || sorted[0][1] > sorted[1][1])) winnerF = sorted[0][0];
      } else {
        events.push({ type: "GAME_OVER", winner: null, did_someone_win: false });
        await sql`UPDATE games SET status = 'FINISHED' WHERE id = ${game_id}`;
      }

      if (winnerF) {
        events.push({ type: "GAME_OVER", winner: winnerF, did_someone_win: true });
        const winP = activePlayers.find(p => p.faction === winnerF);
        await sql`UPDATE games SET status = 'FINISHED', winner = ${winP?.id} WHERE id = ${game_id}`;
        if (winP) await sql`UPDATE players SET is_winner = TRUE WHERE id = ${winP.id}`;
      }

      // Phase 6: Acquisition
      for (const p of remaining) {
        const tray = factionTrayMap.get(p.faction as Faction) || [];
        if (tray.length < 9) {
          const r = Math.random();
          let type: PieceType | null = null;
          if (r < 0.25) type = "NEUTRINO";
          else if (r < 0.45) type = "ECLIPSE";
          else if (r < 0.65) type = "PARALLAX";
          else if (r < 0.75) type = "STAR_CITY";

          if (type) {
            const id = crypto.randomUUID();
            const piece: Piece = { id, faction: p.faction as Faction, type, x: null, y: null, tether_id: null, is_anchored: false, is_stunned: false, is_visible: type !== "NEUTRINO", is_in_tray: true };
            pieceMap.set(id, piece);
            tray.push(id);
            events.push({ type: "PIECE_ACQUIRED", faction: p.faction as Faction, piece_type: type, new_piece_id: id });
          }
        }
      }

      // Phase 7: Save
      const finalState = Array.from(pieceMap.values());
      await sql`INSERT INTO turn_events (game_id, turn_number, events) VALUES (${game_id}, ${turn_number}, ${JSON.stringify(events)})`;
      await sql`INSERT INTO turn_states (game_id, turn_number, state) VALUES (${game_id}, ${turn_number + 1}, ${JSON.stringify(finalState)})`;
      await sql`UPDATE games SET turn_number = ${turn_number + 1}, status = ${winnerF || remaining.length <= 1 ? "FINISHED" : "PLANNING"} WHERE id = ${game_id}`;
      await sql`UPDATE players SET is_ready = FALSE WHERE game_id = ${game_id} AND is_eliminated = FALSE`;
    });

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(null, { status: error instanceof ServerError ? error.statusCode : 500 });
  }
});
