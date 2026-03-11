import { BotContext } from "../bot-context.ts";

export function planPlacements(context: BotContext) {
  const trayIds = context.factionTrayMap.get(context.currentFaction) || [];
  if (trayIds.length === 0) return;

  const trayPieces = trayIds
    .map((id) => context.getPiece(id)!)
    .filter((p) => p !== undefined);

  // Get all friendly anchored cities with capacity
  const cities = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
    .map((id) => context.getPiece(id)!)
    .filter((p) => p.type === "STAR_CITY" && p.is_anchored);

  for (const piece of trayPieces) {
    if (piece.type === "ECLIPSE" || piece.type === "PARALLAX") {
      // Find a city with capacity
      const city = cities.find(
        (c) => context.getTetheredCount(c.id) < context.params.max_ships_per_city
      );
      if (!city) continue;

      // Find an empty adjacent square
      const adj = context.getAdjacent(city as { x: number; y: number });
      const target = adj.find((coord) => !context.isOccupied(coord));

      if (target) {
        context.addAction({
          type: "PLACE_ACT",
          tray_piece_id: piece.id,
          city_id: city.id,
          target: target,
        });
      }
    } else {
      // STAR_CITY or NEUTRINO - can be placed near any city (anchored or not)
      const allCities = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
        .map((id) => context.getPiece(id)!)
        .filter((p) => p.type === "STAR_CITY");

      for (const city of allCities) {
        const adj = context.getAdjacent(city as { x: number; y: number });
        const target = adj.find((coord) => !context.isOccupied(coord));
        if (target) {
          context.addAction({
            type: "PLACE_ACT",
            tray_piece_id: piece.id,
            city_id: null,
            target: target,
          });
          break;
        }
      }
    }
  }
}
