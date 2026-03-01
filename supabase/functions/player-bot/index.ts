import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { ServerError } from "../_shared/server-error.ts";
import { PlannedAction } from "../_shared/types.ts";

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
      return new Response( null, { status: 200 } );
    }

    // Fetch all active bots for this game
    const bots = await sql<PlayerRow[]>`
      SELECT id 
      FROM players 
      WHERE game_id = ${game_id} 
        AND is_bot = TRUE 
        AND is_eliminated = FALSE
    `;

    if (bots.length === 0) {
      return new Response( null, { status: 200 } );
    }

    console.log(`Playing as ${bots.length} bot(s) for game ${game_id}`)

    // Process each bot
    await sql.begin(async (sql) => {
      for (const bot of bots) {
        // TODO: Implement actual AI logic here to populate 'actions'.
        const actions: PlannedAction[] = [];

        // 1. Submit planned actions for the current turn (UPSERT)
        await sql`
          INSERT INTO turn_planned_actions (game_id, player_id, turn_number, actions)
          VALUES (${game_id}, ${bot.id}, ${turn_number}, ${sql.json(actions)})
          ON CONFLICT (game_id, player_id, turn_number) 
          DO UPDATE SET 
            actions = EXCLUDED.actions,
            submitted_at = NOW()
        `;

        // 2. Mark bot as ready
        await sql`
          UPDATE players 
          SET is_ready = TRUE 
          WHERE id = ${bot.id}
        `;
      }
    });

    return new Response( null, { status: 200 } );
  } catch (error) {
    console.error(error);
    const status = error instanceof ServerError ? error.statusCode : 500;
    return new Response( null, { status } );
  }
});
