import { Coordinate } from "../_shared/types.ts";

export function getTorusDistance(a: Coordinate, b: Coordinate, size: number): number {
  const dx = Math.abs(a.x - b.x);
  const dy = Math.abs(a.y - b.y);
  
  const dxt = Math.min(dx, size - dx);
  const dyt = Math.min(dy, size - dy);
  
  // Chebyshev distance (max of dx, dy) is often used for grid movement
  // but for "spacing" maybe Euclidean or Manhattan? 
  // Let's use Manhattan distance for star spacing.
  return dxt + dyt;
}

export function generateStars(count: number, size: number): Coordinate[] {
  const stars: Coordinate[] = [];
  let attempts = 0;
  
  while (stars.length < count && attempts < 500) {
    const newStar = {
      x: Math.floor(Math.random() * size),
      y: Math.floor(Math.random() * size),
    };
    
    // Ensure it's not on top of another star and has some breathing room
    const isTooClose = stars.some(s => getTorusDistance(s, newStar, size) < 2);
    
    if (!isTooClose) {
      stars.push(newStar);
    }
    attempts++;
  }
  
  return stars;
}

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
