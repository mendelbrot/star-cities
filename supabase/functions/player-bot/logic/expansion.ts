import { BotContext } from "../bot-context.ts";
import { Coordinate, Piece } from "../../_shared/types.ts";

export function planExpansion(context: BotContext) {
  const cities = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
    .map((id) => context.getPiece(id)!)
    .filter((p) => p !== undefined && p.type === "STAR_CITY" && p.x !== null && p.y !== null);

  for (const city of cities) {
    if (city.is_anchored) {
      // Already anchored, stay put for now.
      continue;
    }

    // Try to anchor if adjacent to a star
    const adjacentStars = context.stars.filter(
      (s) => context.getDistance(city as Coordinate, s) === 1
    );

    if (adjacentStars.length > 0) {
      context.addAction({
        type: "ANCHOR_ACT",
        piece_id: city.id,
        is_anchored: true,
      });
    } else {
      // Move toward nearest untapped star
      const untappedStars = getUntappedStars(context);
      if (untappedStars.length > 0) {
        const nearestStar = untappedStars.sort((a, b) => {
          return context.getDistance(city as Coordinate, a) - context.getDistance(city as Coordinate, b);
        })[0];

        const bestMove = getBestMoveTowardStar(context, city, nearestStar);
        if (bestMove) {
          context.addAction({
            type: "MOVE_ACT",
            piece_id: city.id,
            to: bestMove,
          });
        }
      }
    }
  }
}

function getUntappedStars(context: BotContext): Coordinate[] {
  // A star is untapped if no friendly city is anchored adjacent to it
  const friendlyAnchoredCities = Array.from(context.pieceMap.values()).filter(
    (p) => p.faction === context.currentFaction && p.type === "STAR_CITY" && p.is_anchored
  );

  return context.stars.filter((star) => {
    const isTapped = friendlyAnchoredCities.some(
      (city) => context.getDistance(city as Coordinate, star) === 1
    );
    return !isTapped;
  });
}

function getBestMoveTowardStar(
  context: BotContext,
  city: Piece,
  target: Coordinate
): Coordinate | null {
  const moves = context.getAdjacent(city as Coordinate);
  return moves
    .filter((m) => !context.isOccupied(m))
    .sort((a, b) => {
      return context.getDistance(a, target) - context.getDistance(b, target);
    })[0] || null;
}
