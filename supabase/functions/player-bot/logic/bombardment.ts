import { BotContext } from "../bot-context.ts";
import { Coordinate } from "../../_shared/types.ts";

export function planBombardment(context: BotContext) {
  const eclipses = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
    .map((id) => context.getPiece(id)!)
    .filter((p) => p !== undefined && p.type === "ECLIPSE" && p.x !== null && p.y !== null);

  for (const eclipse of eclipses) {
    // Find enemy in range 2
    const enemies = Array.from(context.pieceMap.values()).filter(
      (p) => p.faction !== context.currentFaction && !p.is_in_tray
    );

    const target = enemies.find((enemy) => {
      const dist = context.getDistance(eclipse as Coordinate, enemy as Coordinate);
      return dist <= 2;
    });

    if (target) {
      context.addAction({
        type: "BOMBARD_ACT",
        piece_id: eclipse.id,
        target_id: target.id,
      });
    }
  }
}
