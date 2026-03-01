import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { ServerError } from "../_shared/server-error.ts";
import { prepare } from "./phases/01-prepare.ts";
import { resolveIntents } from "./phases/02-intent.ts";
import { resolveCombat } from "./phases/03-combat.ts";
import { resolveLifecycle } from "./phases/04-lifecycle.ts";
import { finalize } from "./phases/05-finalize.ts";

interface WebhookPayload {
  record: {
    id: string;
    status: string;
    turn_number: number;
  };
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

    await sql.begin(async (tx) => {
      // Phase 1: Preparation (Fetch & Index)
      const { context, plannedActions, factionMoveTargetsMap } = await prepare(tx, game_id, turn_number);

      // Phase 2: Intent Resolution (PLACE, TETHER, ANCHOR)
      resolveIntents(context, plannedActions, factionMoveTargetsMap);

      // Phase 3: Combat Resolution (BOMBARD, MOVE, BATTLE)
      resolveCombat(context, plannedActions);

      // Phase 4: Lifecycle & Economy (Elimination, Acquisition)
      await resolveLifecycle(tx, context);

      // Phase 5: Conclusion (Win Check, Persistence)
      await finalize(tx, context);
    });

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(null, { 
      status: error instanceof ServerError ? error.statusCode : 500,
    });
  }
});
