// Supabase Edge Function: player-bot
// This function acts as a simple automated player to fill game slots or for testing.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

console.log("Hello from player-bot!")

serve(async (req) => {
  try {
    const { game_id, player_id } = await req.json()

    console.log(`Bot processing move for player: ${player_id} in game: ${game_id}`)

    // TODO: Implement simple bot logic
    // 1. Analyze current visible state
    // 2. Decide on movements/actions
    // 3. Submit turn_planned_actions to the database
    // 4. Mark player as 'is_ready'

    return new Response(
      JSON.stringify({ message: "Bot turn planned.", game_id, player_id }),
      { headers: { "Content-Type": "application/json" }, status: 200 },
    )
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "An unknown error occurred"
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { headers: { "Content-Type": "application/json" }, status: 400 },
    )
  }
})
