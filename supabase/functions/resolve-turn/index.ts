import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { GameEvent, GameParameters, Piece, PlannedAction } from "../_shared/types.ts";
import { ServerError } from "../_shared/server-error.ts";

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
        SELECT status, game_parameters FROM games WHERE id = ${game_id} FOR UPDATE
      `;

      if (!game) {
        throw new ServerError(`Game not found: ${game_id}`, 400);
      }

      if (game.status !== "RESOLVING") {
        throw new ServerError(`Game status changed to ${game.status}.`, 400);
      }

      const players = await sql<PlayerRow[]>`
        SELECT id, faction, is_eliminated FROM players WHERE game_id = ${game_id}
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
        is_visible: p.type === "NEUTRINO" ? false : p.is_visible,
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

      // TODO: Phase 2: Resolve non-conflict actions (PLACE, TETHER, ANCHOR)

    });

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response(null, { status });
  }
});
