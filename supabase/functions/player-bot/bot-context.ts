import { Coordinate, Faction, GameParameters, Piece, PlannedAction, Player } from "../_shared/types.ts";
import { getAdjacentCoordinates, getTorusDistance, isSameCoordinate } from "../_shared/map.ts";

export class BotContext {
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
  
  // Predicted state for current turn planning
  plannedActions: PlannedAction[] = [];
  predictedCoordinateMap = new Map<string, string>(); // (x,y) -> piece_id (after PLACEMENT and MOVE)
  
  currentBotPlayerId: string;
  currentFaction: Faction;

  constructor(
    game_id: string,
    turn_number: number,
    params: GameParameters,
    stars: Coordinate[],
    players: Player[],
    initialState: Piece[],
    currentBotPlayerId: string
  ) {
    this.game_id = game_id;
    this.turn_number = turn_number;
    this.params = params;
    this.stars = stars;
    this.players = players;
    this.currentBotPlayerId = currentBotPlayerId;

    const currentPlayer = players.find(p => p.id === currentBotPlayerId);
    if (!currentPlayer) throw new Error(`Bot player ${currentBotPlayerId} not found`);
    this.currentFaction = currentPlayer.faction;

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
        this.predictedCoordinateMap.set(key, p.id);
        this.factionPlacedPiecesMap.get(p.faction)?.push(p.id);

        if (p.tether_id) {
          const ships = this.tetherMap.get(p.tether_id) || [];
          ships.push(p.id);
          this.tetherMap.set(p.tether_id, ships);
        }
      }
    });
  }

  addAction(action: PlannedAction) {
    this.plannedActions.push(action);
    
    // Update predicted coordinate map
    if (action.type === "PLACE_ACT") {
      this.predictedCoordinateMap.set(`${action.target.x},${action.target.y}`, action.tray_piece_id);
    } else if (action.type === "MOVE_ACT") {
      const piece = this.pieceMap.get(action.piece_id);
      if (piece && piece.x !== null && piece.y !== null) {
        // If we move away, we should ideally clear the old square, 
        // but since it's simultaneous, we just mark the NEW square as occupied.
        // For simplicity of bot logic, let's just mark the target as occupied.
        this.predictedCoordinateMap.set(`${action.to.x},${action.to.y}`, action.piece_id);
      }
    }
  }

  getPiece(id: string): Piece | undefined {
    return this.pieceMap.get(id);
  }

  getPieceAt(coord: Coordinate): Piece | undefined {
    const id = this.coordinateMap.get(`${coord.x},${coord.y}`);
    return id ? this.pieceMap.get(id) : undefined;
  }

  isOccupied(coord: Coordinate): boolean {
    return this.predictedCoordinateMap.has(`${coord.x},${coord.y}`) || this.isStarAt(coord);
  }

  isStarAt(coord: Coordinate): boolean {
    return this.stars.some(s => isSameCoordinate(s, coord));
  }

  getDistance(a: Coordinate, b: Coordinate): number {
    return getTorusDistance(a, b, this.params.grid_size);
  }

  getAdjacent(coord: Coordinate): Coordinate[] {
    return getAdjacentCoordinates(coord, this.params.grid_size);
  }

  getTetheredCount(cityId: string): number {
    // Count current tethers + planned tethers
    const currentCount = this.tetherMap.get(cityId)?.length || 0;
    const plannedPlaces = this.plannedActions.filter(a => a.type === "PLACE_ACT" && a.city_id === cityId).length;
    const plannedTethers = this.plannedActions.filter(a => a.type === "TETHER_ACT" && a.city_id === cityId).length;
    return currentCount + plannedPlaces + plannedTethers;
  }
}
