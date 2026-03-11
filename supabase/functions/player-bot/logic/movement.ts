import { BotContext } from "../bot-context.ts";
import { Coordinate, Piece } from "../../_shared/types.ts";

export function planMovement(context: BotContext) {
  const pieces = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
    .map((id) => context.getPiece(id)!)
    .filter((p) => p !== undefined && p.x !== null && p.y !== null);

  for (const piece of pieces) {
    if (piece.type === "NEUTRINO") {
      planNeutrinoMove(context, piece);
    } else if (piece.type === "PARALLAX") {
      planParallaxMove(context, piece);
    } else if (piece.type === "ECLIPSE") {
      planEclipseMove(context, piece);
    }
  }
}

function planNeutrinoMove(context: BotContext, piece: Piece) {
  // Move away from friendly star cities (Explorer)
  const friendlyCities = (context.factionPlacedPiecesMap.get(context.currentFaction) || [])
    .map((id) => context.getPiece(id)!)
    .filter((p) => p !== undefined && p.type === "STAR_CITY");

  let avoidanceTargets = friendlyCities;

  // Fallback to enemy cities if no friendly cities exist
  if (avoidanceTargets.length === 0) {
    avoidanceTargets = Array.from(context.pieceMap.values()).filter(
      (p) => p.faction !== context.currentFaction && p.type === "STAR_CITY"
    );
  }

  if (avoidanceTargets.length === 0) return;

  const nearestTarget = getNearest(context, piece as Coordinate, avoidanceTargets);
  const moves = context.getAdjacent(piece as Coordinate);
  const validMoves = moves.filter((m) => !context.isOccupied(m));

  if (validMoves.length === 0) return;

  // 10% chance to just pick a random valid move for some unpredictability
  if (Math.random() < 0.1) {
    const randomMove = validMoves[Math.floor(Math.random() * validMoves.length)];
    context.addAction({
      type: "MOVE_ACT",
      piece_id: piece.id,
      to: randomMove,
    });
    return;
  }

  const bestMove = validMoves.sort((a, b) => {
    const distA = context.getDistance(a, nearestTarget as Coordinate);
    const distB = context.getDistance(b, nearestTarget as Coordinate);
    return distB - distA; // Descending distance (farther is better)
  })[0];

  if (bestMove) {
    context.addAction({
      type: "MOVE_ACT",
      piece_id: piece.id,
      to: bestMove,
    });
  }
}

function planParallaxMove(context: BotContext, piece: Piece) {
  // Move toward/onto nearest enemy ship
  const enemies = Array.from(context.pieceMap.values()).filter(
    (p) => p.faction !== context.currentFaction && !p.is_in_tray
  );

  if (enemies.length === 0) return;

  const nearestEnemy = getNearest(context, piece as Coordinate, enemies);
  const bestMove = getBestMoveToward(context, piece, nearestEnemy as Coordinate, 2);

  if (bestMove) {
    context.addAction({
      type: "MOVE_ACT",
      piece_id: piece.id,
      to: bestMove,
    });
  }
}

function planEclipseMove(context: BotContext, piece: Piece) {
  // Move toward nearest enemy ship, try to maintain distance 2
  const enemies = Array.from(context.pieceMap.values()).filter(
    (p) => p.faction !== context.currentFaction && !p.is_in_tray
  );

  if (enemies.length === 0) return;

  const nearestEnemy = getNearest(context, piece as Coordinate, enemies);
  const bestMove = getBestMoveToward(context, piece, nearestEnemy as Coordinate, 1, 2);

  if (bestMove) {
    context.addAction({
      type: "MOVE_ACT",
      piece_id: piece.id,
      to: bestMove,
    });
  }
}

function getNearest(context: BotContext, from: Coordinate, targets: Piece[]): Piece {
  return targets.sort((a, b) => {
    const distA = context.getDistance(from, a as Coordinate);
    const distB = context.getDistance(from, b as Coordinate);
    return distA - distB;
  })[0];
}

function getBestMoveToward(
  context: BotContext,
  piece: Piece,
  target: Coordinate,
  maxDist: number,
  idealDist: number = 0
): Coordinate | null {
  const size = context.params.grid_size;
  const currentPos = piece as Coordinate;
  const possibleMoves: Coordinate[] = [];

  // Parallax has maxDist 2, Eclipse has maxDist 1
  for (let dx = -maxDist; dx <= maxDist; dx++) {
    for (let dy = -maxDist; dy <= maxDist; dy++) {
      if (dx === 0 && dy === 0) continue;
      
      const move = {
        x: (currentPos.x + dx + size) % size,
        y: (currentPos.y + dy + size) % size,
      };

      if (context.isOccupied(move)) continue;

      // If tethered, must stay within range 2 of tether city
      if (piece.tether_id) {
        const city = context.getPiece(piece.tether_id);
        if (city && city.x !== null && city.y !== null) {
          if (context.getDistance(move, city as Coordinate) > 2) continue;
        }
      }

      possibleMoves.push(move);
    }
  }

  if (possibleMoves.length === 0) return null;

  // 10% chance to just pick a random valid move for some unpredictability
  if (Math.random() < 0.1) {
    return possibleMoves[Math.floor(Math.random() * possibleMoves.length)];
  }

  return possibleMoves.sort((a, b) => {
    const distA = context.getDistance(a, target);
    const distB = context.getDistance(b, target);
    
    if (idealDist > 0) {
      return Math.abs(distA - idealDist) - Math.abs(distB - idealDist);
    }
    return distA - distB;
  })[0];
}
