import postgres from "postgres";
import { Player } from "../../_shared/types.ts";
import { TurnContext } from "../context.ts";

export async function finalize(sql: postgres.Sql, context: TurnContext) {
  context.currentStep = 7;
  const { game_id, turn_number, players, pieceMap } = context;

  const remainingPlayers = players.filter((p: Player) => !p.is_eliminated);
  const remainingHumans = remainingPlayers.filter((p: Player) => !p.is_bot);
  
  const winnerF = context.getWinner();

  if (winnerF) {
    context.addEvent({ type: "GAME_OVER", winner: winnerF, did_someone_win: true });
  } else if (remainingHumans.length === 0) {
    context.addEvent({ type: "GAME_OVER", winner: null, did_someone_win: false });
  }

  const starCounts = context.getFactionStarCounts();

  // Create player ranking
  const playerRanking = players.map(p => ({
    player_id: p.id,
    faction: p.faction,
    star_count: starCounts.get(p.faction) || 0
  })).sort((a, b) => b.star_count - a.star_count);

  context.currentStep = 7;
  context.captureSnapshot();

  // Final Persistence
  const finalState = Array.from(pieceMap.values());
  
  // turn_events is for the current turn being resolved
  await sql`
    INSERT INTO turn_events (game_id, turn_number, events, snapshots, player_ranking) 
    VALUES (${game_id}, ${turn_number}, ${sql.json(context.events)}, ${sql.json(context.snapshots)}, ${sql.json(playerRanking)})
    ON CONFLICT (game_id, turn_number) DO UPDATE SET 
      events = EXCLUDED.events,
      snapshots = EXCLUDED.snapshots,
      player_ranking = EXCLUDED.player_ranking
  `;

  // turn_states is for the START of the NEXT turn
  await sql`
    INSERT INTO turn_states (game_id, turn_number, state) 
    VALUES (${game_id}, ${turn_number + 1}, ${sql.json(finalState)})
    ON CONFLICT (game_id, turn_number) DO UPDATE SET state = EXCLUDED.state
  `;
  
  const gameStatus = (winnerF || remainingPlayers.length <= 1 || remainingHumans.length === 0) ? "FINISHED" : "PLANNING";
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
