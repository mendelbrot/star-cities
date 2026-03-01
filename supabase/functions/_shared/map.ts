import { Coordinate } from "./types.ts";

/**
 * Gets the Manhattan distance between two points on a torus grid.
 */
export function getTorusManhattanDistance(a: Coordinate, b: Coordinate, size: number): number {
  const dx = Math.abs(a.x - b.x);
  const dy = Math.abs(a.y - b.y);
  const dxt = Math.min(dx, size - dx);
  const dyt = Math.min(dy, size - dy);
  return dxt + dyt;
}

/**
 * Gets the Chebyshev distance (max(dx, dy)) between two points on a torus grid.
 * This corresponds to the number of moves a piece (including diagonals) 
 * needs to travel between two points.
 */
export function getTorusDistance(a: Coordinate, b: Coordinate, size: number): number {
  const dx = Math.abs(a.x - b.x);
  const dy = Math.abs(a.y - b.y);
  const dxt = Math.min(dx, size - dx);
  const dyt = Math.min(dy, size - dy);
  return Math.max(dxt, dyt);
}

/**
 * Returns all coordinates adjacent (distance 1, including diagonals) to the given coordinate.
 */
export function getAdjacentCoordinates(coord: Coordinate, size: number): Coordinate[] {
  const adj: Coordinate[] = [];
  for (let dx = -1; dx <= 1; dx++) {
    for (let dy = -1; dy <= 1; dy++) {
      if (dx === 0 && dy === 0) continue;
      adj.push({
        x: (coord.x + dx + size) % size,
        y: (coord.y + dy + size) % size,
      });
    }
  }
  return adj;
}

/**
 * Normalizes a coordinate to ensure it stays within the torus grid boundaries.
 */
export function normalizeCoordinate(coord: Coordinate, size: number): Coordinate {
  return {
    x: (coord.x % size + size) % size,
    y: (coord.y % size + size) % size,
  };
}

/**
 * Checks if two coordinates are the same.
 */
export function isSameCoordinate(a: Coordinate, b: Coordinate): boolean {
  return a.x === b.x && a.y === b.y;
}
