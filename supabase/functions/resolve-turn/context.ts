import { Coordinate, Faction, GameEvent, GameParameters, Piece, Player } from "../_shared/types.ts";
import { getAdjacentCoordinates, isSameCoordinate } from "../_shared/map.ts";

export interface PieceTurnContext {
  wasJustPlaced?: boolean;
  wasJustDeanchored?: boolean;
  wasJustAnchored?: boolean;
  wasJustBombarded?: boolean;
}

export class TurnContext {
  game_id: string;
  turn_number: number;
  params: GameParameters;
  stars: Coordinate[];
  players: Player[];
  
  pieceMap = new Map<string, Piece>(); // id -> Piece
  coordinateMap = new Map<string, string>(); // (x,y) -> piece_id
  factionPlacedPiecesMap = new Map<string, string[]>(); // faction -> list of piece_ids
  factionTrayMap = new Map<string, string[]>(); // faction -> list of piece_ids
  tetherMap = new Map<string, string[]>(); // city_id -> list of ship_ids
  pieceContexts = new Map<string, PieceTurnContext>(); // piece_id -> PieceTurnContext
  pendingPlacements = new Map<string, string[]>(); // coordKey -> list of piece_ids
  events: GameEvent[] = [];
  snapshots: Record<number, Piece[]> = {}; // replay_step -> list of Piece objects
  currentStep: number = 0;

  constructor(
    game_id: string,
    turn_number: number,
    params: GameParameters,
    stars: Coordinate[],
    players: Player[],
    initialState: Piece[]
  ) {
    this.game_id = game_id;
    this.turn_number = turn_number;
    this.params = params;
    this.stars = stars;
    this.players = players;

    // Initialize faction maps
    players.forEach((p) => {
      this.factionPlacedPiecesMap.set(p.faction, []);
      this.factionTrayMap.set(p.faction, []);
    });

    // Populate indexes
    initialState.forEach((p) => {
      this.pieceMap.set(p.id, p);

      if (p.is_in_tray || p.x === null || p.y === null) {
        this.factionTrayMap.get(p.faction)?.push(p.id);
      } else {
        const key = `${p.x},${p.y}`;
        this.coordinateMap.set(key, p.id);
        this.factionPlacedPiecesMap.get(p.faction)?.push(p.id);

        if (p.tether_id) {
          const ships = this.tetherMap.get(p.tether_id) || [];
          ships.push(p.id);
          this.tetherMap.set(p.tether_id, ships);
        }
      }
    });
  }

  getFactionStarCounts(): Map<string, number> {
    const counts = new Map<string, number>();
    const size = this.params.grid_size;

    for (const p of this.players) {
      if (p.is_eliminated) {
        counts.set(p.faction, 0);
        continue;
      }
      const f = p.faction;
      const anchoredStars = new Set<string>();
      (this.factionPlacedPiecesMap.get(f) || [])
        .map((id: string) => this.pieceMap.get(id)!)
        .filter((p: Piece) => p.type === "STAR_CITY" && p.is_anchored)
        .forEach((city: Piece) => {
          getAdjacentCoordinates(city as Coordinate, size).forEach((a: Coordinate) => {
            if (this.isStarAt(a)) {
              anchoredStars.add(`${a.x},${a.y}`);
            }
          });
        });
      counts.set(f, anchoredStars.size);
    }
    return counts;
  }

  addEvent(event: GameEvent) {
    event.replay_step = this.currentStep;
    this.events.push(event);
  }

  getPiece(id: string): Piece | undefined {
    return this.pieceMap.get(id);
  }

  getPieceAt(coord: Coordinate): Piece | undefined {
    const id = this.coordinateMap.get(`${coord.x},${coord.y}`);
    return id ? this.pieceMap.get(id) : undefined;
  }

  updatePiecePosition(pieceId: string, to: Coordinate | null) {
    const piece = this.pieceMap.get(pieceId);
    if (!piece) return;

    // Remove from old coordinate map if it was placed
    if (piece.x !== null && piece.y !== null) {
      this.coordinateMap.delete(`${piece.x},${piece.y}`);
    }

    // Update piece coordinates
    piece.x = to?.x ?? null;
    piece.y = to?.y ?? null;
    piece.is_in_tray = to === null;

    // Update coordinate map and faction maps if moved to board
    if (to !== null) {
      const key = `${to.x},${to.y}`;
      this.coordinateMap.set(key, pieceId);
      
      const tray = this.factionTrayMap.get(piece.faction) || [];
      const idx = tray.indexOf(pieceId);
      if (idx !== -1) {
        tray.splice(idx, 1);
        this.factionPlacedPiecesMap.get(piece.faction)?.push(pieceId);
      }
    } else {
      // Moved to tray (or removed)
      const placed = this.factionPlacedPiecesMap.get(piece.faction) || [];
      const idx = placed.indexOf(pieceId);
      if (idx !== -1) {
        placed.splice(idx, 1);
        this.factionTrayMap.get(piece.faction)?.push(pieceId);
      }
    }
  }

  removePiece(pieceId: string, skipTetherLoss = false) {
    const piece = this.pieceMap.get(pieceId);
    if (!piece) return;

    if (piece.x !== null && piece.y !== null) {
      const key = `${piece.x},${piece.y}`;
      this.coordinateMap.delete(key);
      
      // Also remove from pendingPlacements if present
      const pending = this.pendingPlacements.get(key) || [];
      if (pending.includes(pieceId)) {
        this.pendingPlacements.set(key, pending.filter(id => id !== pieceId));
        if (this.pendingPlacements.get(key)?.length === 0) {
          this.pendingPlacements.delete(key);
        }
      }
    }

    const placed = this.factionPlacedPiecesMap.get(piece.faction) || [];
    this.factionPlacedPiecesMap.set(piece.faction, placed.filter(id => id !== pieceId));
    
    const tray = this.factionTrayMap.get(piece.faction) || [];
    this.factionTrayMap.set(piece.faction, tray.filter(id => id !== pieceId));

    if (piece.type === "STAR_CITY") {
      if (!skipTetherLoss) {
        this.handleTetherLoss(pieceId);
      }
    } else if (piece.tether_id) {
      const ships = this.tetherMap.get(piece.tether_id) || [];
      this.tetherMap.set(piece.tether_id, ships.filter(id => id !== pieceId));
    }

    this.pieceMap.delete(pieceId);
    this.pieceContexts.delete(pieceId);
  }

  captureSnapshot() {
    // Deep clone pieces to capture state at this point in time
    this.snapshots[this.currentStep] = Array.from(this.pieceMap.values()).map(p => ({ ...p }));
  }

  handleTetherLoss(lostCityId: string) {
    const tetheredShips = this.tetherMap.get(lostCityId) || [];
    for (const shipId of tetheredShips) {
      const ship = this.pieceMap.get(shipId);
      if (ship) {
        this.addEvent({
          type: "SHIP_LOST_TETHER",
          faction: ship.faction,
          piece_id: ship.id,
        });
        this.removePiece(shipId);
      }
    }
    this.tetherMap.delete(lostCityId);
  }

  isStarAt(coord: Coordinate): boolean {
    return this.stars.some(s => isSameCoordinate(s, coord));
  }

  getWinner(): Faction | null {
    const remainingPlayers = this.players.filter((p: Player) => !p.is_eliminated);
    if (remainingPlayers.length === 0) return null;
    if (remainingPlayers.length === 1) return remainingPlayers[0].faction as Faction;

    const starCounts = this.getFactionStarCounts();
    const sorted = Array.from(starCounts.entries())
      .filter(([f]) => this.players.some(p => p.faction === f && !p.is_eliminated))
      .sort((a, b) => b[1] - a[1]);

    if (
      sorted.length > 0 && 
      sorted[0][1] >= this.params.star_count_to_win && 
      (sorted.length === 1 || sorted[0][1] > sorted[1][1])
    ) {
      return sorted[0][0] as Faction;
    }

    return null;
  }
}
