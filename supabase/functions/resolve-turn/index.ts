import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { Coordinate, Faction, GameEvent, GameParameters, Piece, PlannedAction } from "../_shared/types.ts";
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

    });

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response(null, { status });
  }
});
