import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { ServerError } from "../_shared/server-error.ts";
import { Coordinate, GameParameters, Piece, Player } from "../_shared/types.ts";
import { BotContext } from "./bot-context.ts";
import { planPlacements } from "./logic/placement.ts";
import { planMovement } from "./logic/movement.ts";
import { planBombardment } from "./logic/bombardment.ts";
import { planExpansion } from "./logic/expansion.ts";

interface WebhookPayload {
  record: {
    id: string;
    status: string;
    turn_number: number;
  };
}

interface PlayerRow {
  id: string;
}

serve(async (req) => {
  try {
    const body: WebhookPayload = await req.json();
    const { record } = body;
    const { id: game_id, status, turn_number } = record;

    if (status !== "PLANNING") {
      return new Response(null, { status: 200 });
    }

    // Fetch game data
    const [game] = await sql`
      SELECT status, game_parameters, stars FROM games WHERE id = ${game_id}
    `;
    if (!game) throw new ServerError("Game not found", 404);

    const players = await sql<Player[]>`
      SELECT * FROM players WHERE game_id = ${game_id}
    `;

    const [turnState] = await sql`
      SELECT state FROM turn_states WHERE game_id = ${game_id} AND turn_number = ${turn_number}
    `;
    if (!turnState) throw new ServerError("Turn state not found", 404);

    const bots = players.filter(p => p.is_bot && !p.is_eliminated);

    if (bots.length === 0) {
      return new Response(null, { status: 200 });
    }

    console.log(`Processing ${bots.length} bot(s) for game ${game_id}`);

    for (const bot of bots) {
      const context = new BotContext(
        game_id,
        turn_number,
        game.game_parameters as GameParameters,
        game.stars as Coordinate[],
        players,
        turnState.state as Piece[],
        bot.id
      );

      // 1. Placement
      planPlacements(context);

      // 2. Expansion (Cities moving or anchoring)
      planExpansion(context);

      // 3. Bombardment
      planBombardment(context);

      // 4. Movement
      planMovement(context);

      // Submit actions
      await sql.begin(async (tx) => {
        await tx`
          INSERT INTO turn_planned_actions (game_id, player_id, turn_number, actions)
          VALUES (${game_id}, ${bot.id}, ${turn_number}, ${tx.json(context.plannedActions)})
          ON CONFLICT (game_id, player_id, turn_number) 
          DO UPDATE SET 
            actions = EXCLUDED.actions,
            submitted_at = NOW()
        `;

        await tx`
          UPDATE players 
          SET is_ready = TRUE 
          WHERE id = ${bot.id}
        `;
      });
    }

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response(null, { status });
  }
});
