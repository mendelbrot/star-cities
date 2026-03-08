import postgres from "https://deno.land/x/postgresjs@v3.3.3/mod.js";
import { Faction, Coordinate, Piece, Player } from "../../_shared/types.ts";
import { getAdjacentCoordinates, isSameCoordinate } from "../../_shared/map.ts";
import { TurnContext } from "../context.ts";

export async function finalize(sql: postgres.Sql, context: TurnContext) {
  context.currentStep = 7;
  const { game_id, turn_number, params, stars, players, pieceMap, factionPlacedPiecesMap, events } = context;
  const size = params.grid_size;

  const remainingPlayers = players.filter((p: Player) => !p.is_eliminated);
  let winnerF: Faction | null = null;

  if (remainingPlayers.length === 1) {
    winnerF = remainingPlayers[0].faction as Faction;
  } else if (remainingPlayers.length > 0) {
    const counts = new Map<Faction, number>();
    for (const p of remainingPlayers) {
      const f = p.faction as Faction;
      const anchoredStars = new Set<string>();
      (factionPlacedPiecesMap.get(f) || [])
        .map((id: string) => pieceMap.get(id)!)
        .filter((p: Piece) => p.type === "STAR_CITY" && p.is_anchored)
        .forEach((city: Piece) => {
          getAdjacentCoordinates(city as Coordinate, size).forEach((a: Coordinate) => {
            if (stars.some((s: Coordinate) => isSameCoordinate(s, a))) {
              anchoredStars.add(`${a.x},${a.y}`);
            }
          });
        });
      counts.set(f, anchoredStars.size);
    }
    const sorted = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
    if (sorted.length > 0 && sorted[0][1] >= params.star_count_to_win && (sorted.length === 1 || sorted[0][1] > sorted[1][1])) {
      winnerF = sorted[0][0];
    }
  } else {
    context.addEvent({ type: "GAME_OVER", winner: null, did_someone_win: false });
  }

  if (winnerF) {
    context.addEvent({ type: "GAME_OVER", winner: winnerF, did_someone_win: true });
  }

  // Final Persistence
  const finalState = Array.from(pieceMap.values());
  
  // turn_events is for the current turn being resolved
  await sql`
    INSERT INTO turn_events (game_id, turn_number, events) 
    VALUES (${game_id}, ${turn_number}, ${sql.json(events)})
    ON CONFLICT (game_id, turn_number) DO UPDATE SET events = EXCLUDED.events
  `;

  // turn_states is for the START of the NEXT turn
  await sql`
    INSERT INTO turn_states (game_id, turn_number, state) 
    VALUES (${game_id}, ${turn_number + 1}, ${sql.json(finalState)})
    ON CONFLICT (game_id, turn_number) DO UPDATE SET state = EXCLUDED.state
  `;
  
  const gameStatus = (winnerF || remainingPlayers.length <= 1) ? "FINISHED" : "PLANNING";
  if (winnerF) {
    const winP = remainingPlayers.find((p: Player) => p.faction === winnerF);
    if (winP) {
      await sql`UPDATE games SET turn_number = ${turn_number + 1}, status = ${gameStatus}, winner = ${winP.id} WHERE id = ${game_id}`;
      await sql`UPDATE players SET is_winner = TRUE WHERE id = ${winP.id}`;
    } else {
      await sql`UPDATE games SET turn_number = ${turn_number + 1}, status = ${gameStatus} WHERE id = ${game_id}`;
    }
  } else {
    await sql`UPDATE games SET turn_number = ${turn_number + 1}, status = ${gameStatus} WHERE id = ${game_id}`;
  }
  
  await sql`UPDATE players SET is_ready = FALSE WHERE game_id = ${game_id} AND is_eliminated = FALSE`;
}
