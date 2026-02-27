import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { BombardEvent, Coordinate, Faction, GameEvent, GameParameters, Piece, PlannedAction } from "../_shared/types.ts";
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
}

interface TurnStateRow {
  state: Piece[];
}

interface TurnPlannedActionsRow {
  player_id: string;
  actions: PlannedAction[];
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
        SELECT id, faction FROM players 
        WHERE game_id = ${game_id} AND is_eliminated = FALSE
      `;

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
      const coordinateMap = new Map<string, string>(); // (x,y) -> piece_id (only for pieces on the map)
      const factionPlacedPiecesMap = new Map<string, string[]>(); // faction -> list of piece_ids
      const factionTrayMap = new Map<string, string[]>(); // faction -> list of piece_ids
      const tetherMap = new Map<string, string[]>(); // city_id -> list of ship_ids

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

      // Initialize events list
      const events: GameEvent[] = [];

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

      // Phase 2: Resolve non-conflict actions (PLACE, TETHER, ANCHOR)
      for (const playerActionRow of plannedActions) {
        const player = players.find((p) => p.id === playerActionRow.player_id);
        if (!player) continue;

        for (const action of playerActionRow.actions) {
          if (action.type === "PLACE_ACT") {
            const piece = pieceMap.get(action.tray_piece_id);
            if (!piece || !piece.is_in_tray || piece.faction !== player.faction) continue;

            const isStar = game.stars.some((s) => isSameCoordinate(s, action.target));
            const isOccupied = coordinateMap.has(`${action.target.x},${action.target.y}`);
            if (isStar || isOccupied) continue;

            // Check proximity to city
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

            // Apply PLACE
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

            // Remove old tether
            if (ship.tether_id) {
              const oldShips = tetherMap.get(ship.tether_id) || [];
              tetherMap.set(ship.tether_id, oldShips.filter(id => id !== ship.id));
            }

            // Apply TETHER
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

            // Apply ANCHOR
            city.is_anchored = action.is_anchored;

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
      const bombardEventsMap = new Map<string, BombardEvent>(); // target_id -> BombardEvent

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

            event.attacking_pieces.push({
              piece_id: attacker.id,
              piece_type: attacker.type,
              faction: attacker.faction,
            });
            event.attack_strength += 2; // Eclipse bombardment strength is 2
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

            // Update state and indexes
            if (target.x !== null && target.y !== null) {
              coordinateMap.delete(`${target.x},${target.y}`);
            }
            const factionPlaced = factionPlacedPiecesMap.get(target.faction) || [];
            factionPlacedPiecesMap.set(target.faction, factionPlaced.filter((id) => id !== target.id));

            // If it's a star city, cascade
            if (target.type === "STAR_CITY") {
              lossCascade(target.id);
            } else if (target.tether_id) {
              // Remove from tether map
              const ships = tetherMap.get(target.tether_id) || [];
              tetherMap.set(target.tether_id, ships.filter((id) => id !== target.id));
            }

            pieceMap.delete(target.id);
          }
        }
      }

    });

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response(null, { status });
  }
});
