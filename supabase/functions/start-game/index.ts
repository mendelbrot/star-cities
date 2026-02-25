import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sql } from "../_shared/db.ts";
import { GameParameters, Piece, Faction } from "../_shared/types.ts";
import { generateStars, getAdjacentCoordinates } from "./map.ts";

serve(async (req) => {
  try {
    const body = await req.json();
    console.log("Incoming Webhook Request:", JSON.stringify(body, null, 2));

    const { record } = body;
    const game_id = record.id;

    console.log(`Processing start-game for game_id: ${game_id}`);

    // Fetch game parameters and players in a transaction
    const result = await sql.begin(async (sql) => {
      // 1. Fetch Game and Players
      const [game] = await sql`SELECT status, game_parameters FROM games WHERE id = ${game_id} FOR UPDATE`;
      
      if (!game) {
        throw new Error("Game not found");
      }

      if (game.status !== "STARTING") {
        console.log(`Game ${game_id} is in status ${game.status}, skipping start-game logic.`);
        return { skipped: true, status: game.status };
      }

      const players = await sql`SELECT id, faction FROM players WHERE game_id = ${game_id}`;

      const params = game.game_parameters as GameParameters;
      const size = params.grid_size;

      // 2. Generate Stars
      const stars = generateStars(params.star_count, size);

      // 3. Initialize Turn 1 State
      const pieces: Piece[] = [];
      const updatedPlayers: { id: string, home_star: any }[] = [];

      // Assign each player to a different star (if enough stars exist)
      for (let i = 0; i < players.length; i++) {
        const player = players[i];
        const homeStar = stars[i % stars.length];
        
        updatedPlayers.push({
          id: player.id,
          home_star: homeStar
        });

        // Place initial Star City adjacent to home star (avoiding squares with other stars)
        const adj = getAdjacentCoordinates(homeStar, size);
        const cityPos = adj.find(pos => 
          !stars.some(s => s.x === pos.x && s.y === pos.y) &&
          !pieces.some(p => p.x === pos.x && p.y === pos.y)
        ) || adj[0]; // Fallback to first neighbor if somehow all are stars/occupied

        const city: Piece = {
          id: crypto.randomUUID(),
          faction: player.faction as Faction,
          type: "STAR_CITY",
          x: cityPos.x,
          y: cityPos.y,
          tether_id: null,
          is_anchored: true, // Start anchored to home star
          is_stunned: false,
          is_visible: true,
          is_in_tray: false
        };
        pieces.push(city);

        // Add starting ships to tray
        for (const shipType of params.starting_ships) {
          pieces.push({
            id: crypto.randomUUID(),
            faction: player.faction as Faction,
            type: shipType as any,
            x: null,
            y: null,
            tether_id: city.id, // Tethered to the initial city
            is_anchored: false,
            is_stunned: false,
            is_visible: true,
            is_in_tray: true
          });
        }
      }

      // 4. Update Database
      // Update Game status and stars
      await sql`
        UPDATE games 
        SET status = 'PLANNING', stars = ${sql.json(stars as any)}
        WHERE id = ${game_id}
      `;

      // Update Players home stars
      for (const p of updatedPlayers) {
        await sql`
          UPDATE players 
          SET home_star = ${sql.json(p.home_star as any)}
          WHERE id = ${p.id}
        `;
      }

      // Insert Turn 1 State
      await sql`
        INSERT INTO turn_states (game_id, turn_number, state)
        VALUES (${game_id}, 1, ${sql.json(pieces as any)})
      `;

      return { stars, playerCount: players.length };
    });

    if (result && (result as any).skipped) {
      return new Response(
        JSON.stringify({ message: "Game start skipped", status: (result as any).status }),
        { headers: { "Content-Type": "application/json" }, status: 200 },
      );
    }

    return new Response(
      JSON.stringify({ message: "Game initialized successfully", data: result }),
      { headers: { "Content-Type": "application/json" }, status: 200 },
    );
  } catch (error) {
    console.error(error);
    const errorMessage = error instanceof Error ? error.message : "An unknown error occurred";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { headers: { "Content-Type": "application/json" }, status: 400 },
    );
  }
});
