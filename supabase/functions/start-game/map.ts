import { Coordinate } from "../_shared/types.ts";
import { getTorusManhattanDistance } from "../_shared/map.ts";

export { getAdjacentCoordinates } from "../_shared/map.ts";

/**
 * Generates initial star coordinates for a new game.
 * Uses Manhattan distance for spacing.
 */
export function generateStars(count: number, size: number): Coordinate[] {
  const stars: Coordinate[] = [];
  let attempts = 0;
  
  while (stars.length < count && attempts < 500) {
    const newStar = {
      x: Math.floor(Math.random() * size),
      y: Math.floor(Math.random() * size),
    };
    
    // Ensure it's not on top of another star and has some breathing room
    // For star spacing, Manhattan distance (as originally implemented) is appropriate.
    const isTooClose = stars.some(s => getTorusManhattanDistance(s, newStar, size) < 2);
    
    if (!isTooClose) {
      stars.push(newStar);
    }
    attempts++;
  }
  
  return stars;
}
