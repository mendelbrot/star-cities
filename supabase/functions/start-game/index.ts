import { serve } from "std/http/server.ts";
import { sql } from "../_shared/db.ts";
import { Coordinate, Faction, GameParameters, Piece } from "../_shared/types.ts";
import { generateStars, getAdjacentCoordinates } from "./map.ts";
import { ServerError } from "../_shared/server-error.ts";

interface WebhookPayload {
  record: {
    id: string;
    status: string;
  };
}

interface GameRow {
  status: string;
  game_parameters: GameParameters;
}

interface PlayerRow {
  id: string;
  faction: Faction;
}

serve(async (req) => {
  try {
    const body: WebhookPayload = await req.json();
    const { record } = body;
    const { id: game_id, status } = record;

    if (status !== "STARTING") {
      return new Response( null, { status: 200 } );
    }

    console.log(`Game STARTING: ${game_id}`);

    // Fetch game parameters and players in a transaction
    await sql.begin(async (sql) => {
      // 1. Fetch Game and Players
      const [game] =
        await sql<GameRow[]>`SELECT status, game_parameters FROM games WHERE id = ${game_id} FOR UPDATE`;

      if (!game) {
        throw new ServerError(`Game not found: ${game_id}`, 400);
      }

      if (game.status !== "STARTING") {
        throw new ServerError(`Game status changed to ${game.status}. Was another function invoked?`, 400);
      }

      const players =
        await sql<PlayerRow[]>`SELECT id, faction FROM players WHERE game_id = ${game_id}`;

      const params = game.game_parameters;
      const size = params.grid_size;

      // 2. Generate Stars
      const stars = generateStars(params.star_count, size);

      // 3. Initialize Turn 1 State
      const pieces: Piece[] = [];
      const updatedPlayers: { id: string; home_star: Coordinate }[] = [];

      // Assign each player to a different star (if enough stars exist)
      for (let i = 0; i < players.length; i++) {
        const player = players[i];
        const homeStar = stars[i % stars.length];

        updatedPlayers.push({
          id: player.id,
          home_star: homeStar,
        });

        // Place initial Star City adjacent to home star (avoiding squares with other stars)
        const adj = getAdjacentCoordinates(homeStar, size);
        const cityPos = adj.find((pos) =>
          !stars.some((s) =>
            s.x === pos.x && s.y === pos.y
          ) &&
          !pieces.some((p) => p.x === pos.x && p.y === pos.y)
        ) || adj[0]; // Fallback to first neighbor if somehow all are stars/occupied

        if (cityPos === undefined) {
          throw new ServerError(`No spot to place a Star City`, 500);
        }

        const city: Piece = {
          id: crypto.randomUUID(),
          faction: player.faction,
          type: "STAR_CITY",
          x: cityPos.x,
          y: cityPos.y,
          tether_id: null,
          is_anchored: true, // Start anchored to home star
          is_visible: true,
          is_in_tray: false,
        };
        pieces.push(city);

        // Add starting ships to tray
        for (const shipType of params.starting_ships) {
          pieces.push({
            id: crypto.randomUUID(),
            faction: player.faction,
            type: shipType,
            x: null,
            y: null,
            tether_id: null,
            is_anchored: false,
            is_visible: true,
            is_in_tray: true,
          });
        }
      }

      // 4. Update Database
      // Update Game status and stars
      await sql`
        UPDATE games 
        SET status = 'PLANNING', stars = ${sql.json(stars)}
        WHERE id = ${game_id}
      `;

      // Update Players home stars
      for (const p of updatedPlayers) {
        await sql`
          UPDATE players 
          SET home_star = ${sql.json(p.home_star)}
          WHERE id = ${p.id}
        `;
      }

      // Insert Turn 1 State (UPSERT)
      await sql`
        INSERT INTO turn_states (game_id, turn_number, state)
        VALUES (${game_id}, 1, ${sql.json(pieces)})
        ON CONFLICT (game_id, turn_number) DO UPDATE SET state = EXCLUDED.state
      `;
    });

    return new Response( null, { status: 201 } );
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response( null, { status } );
  }
});
