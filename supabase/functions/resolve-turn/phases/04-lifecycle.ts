import postgres from "https://deno.land/x/postgresjs@v3.3.3/mod.js";
import { Faction, Piece, PieceType, Player } from "../../_shared/types.ts";
import { TurnContext } from "../context.ts";
import { ACQUISITION_PROBABILITIES, MAX_TRAY_SIZE } from "../constants.ts";
import { weightedRoll } from "../utils.ts";

export async function resolveLifecycle(sql: postgres.Sql, context: TurnContext) {
  context.currentStep = 6;
  const { game_id, turn_number, pieceMap, factionPlacedPiecesMap, factionTrayMap, players } = context;

  const activePlayers = players.filter((p: Player) => !p.is_eliminated);
  const eliminated: Faction[] = [];

  for (const p of activePlayers) {
    const faction = p.faction as Faction;
    const cities = (factionPlacedPiecesMap.get(faction) || [])
      .map((id: string) => pieceMap.get(id)!)
      .filter((p: Piece) => p.type === "STAR_CITY");
    
    if (cities.length === 0) {
      eliminated.push(faction);
    }
  }

  for (const f of eliminated) {
    context.addEvent({ type: "FACTION_ELIMINATED", faction: f });
    
    // Remove all pieces of this faction
    const placed = factionPlacedPiecesMap.get(f) || [];
    [...placed].forEach((id: string) => context.removePiece(id));
    
    const tray = factionTrayMap.get(f) || [];
    [...tray].forEach((id: string) => context.removePiece(id));

    // Update database for elimination
    await sql`
      UPDATE players 
      SET is_eliminated = TRUE, eliminated_on_turn = ${turn_number} 
      WHERE game_id = ${game_id} AND faction = ${f}
    `;
    
    // Update local player state
    const player = players.find((p: Player) => p.faction === f);
    if (player) player.is_eliminated = true;
  }

  const remainingPlayers = players.filter((p: Player) => !p.is_eliminated);

  // 4b. Acquisition
  for (const p of remainingPlayers) {
    const faction = p.faction as Faction;
    const tray = factionTrayMap.get(faction) || [];
    
    if (tray.length < MAX_TRAY_SIZE) {
      const type = weightedRoll([
        { label: "NEUTRINO" as PieceType, weight: ACQUISITION_PROBABILITIES.NEUTRINO },
        { label: "ECLIPSE" as PieceType, weight: ACQUISITION_PROBABILITIES.ECLIPSE },
        { label: "PARALLAX" as PieceType, weight: ACQUISITION_PROBABILITIES.PARALLAX },
        { label: "STAR_CITY" as PieceType, weight: ACQUISITION_PROBABILITIES.STAR_CITY },
        { label: null, weight: ACQUISITION_PROBABILITIES.NOTHING },
      ]);

      if (type) {
        const id = crypto.randomUUID();
        const piece: Piece = { 
          id, 
          faction, 
          type, 
          x: null, 
          y: null, 
          tether_id: null, 
          is_anchored: false, 
          is_visible: type !== "NEUTRINO", 
          is_in_tray: true 
        };
        pieceMap.set(id, piece);
        tray.push(id);
        context.addEvent({ type: "PIECE_ACQUIRED", faction, piece_type: type, new_piece_id: id });
      }
    }
  }

  context.captureSnapshot();
}
