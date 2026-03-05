export type Faction = "RED" | "YELLOW" | "GREEN" | "CYAN" | "BLUE" | "MAGENTA";
export type PieceType = "STAR_CITY" | "NEUTRINO" | "ECLIPSE" | "PARALLAX";

export type Player = {
  id: string;
  game_id: string;
  user_id: string | null;
  is_bot: boolean;
  bot_name: string | null;
  faction: Faction;
  is_ready: boolean;
  is_eliminated: boolean;
  eliminated_on_turn: number | null;
  is_winner: boolean;
};

export type GameParameters = {
  grid_size: number;
  star_count: number;
  star_count_to_win: number;
  max_ships_per_city: number;
  starting_ships: PieceType[];
};

export type Coordinate = {
  x: number;
  y: number;
};

export type Piece = {
  id: string;
  faction: Faction;
  type: PieceType;
  x: number | null;         // null if in tray
  y: number | null;         // null if in tray
  tether_id: string | null; // ID of the Star City this ship is tethered to
  is_anchored: boolean;
  is_visible: boolean;
  is_in_tray: boolean;
};

export type MoveAction = {
  type: "MOVE_ACT";
  piece_id: string;
  to: Coordinate;
};

export type BombardAction = {
  type: "BOMBARD_ACT";
  piece_id: string;
  target_id: string;
};

export type TetherAction = {
  type: "TETHER_ACT";
  ship_id: string;
  city_id: string;
};

export type AnchorAction = {
  type: "ANCHOR_ACT";
  piece_id: string;
  is_anchored: boolean;
};

export type PlaceAction = {
  type: "PLACE_ACT";
  tray_piece_id: string;
  city_id: string | null;
  target: Coordinate;
};

export type PlannedAction = 
  | MoveAction 
  | BombardAction 
  | TetherAction 
  | AnchorAction 
  | PlaceAction;

// Event Types
export type MoveEvent = {
  type: "MOVE";
  faction: Faction;
  piece_id: string;
  from: Coordinate;
  to: Coordinate;
};

export type TetherEvent = {
  type: "TETHER";
  faction: Faction;
  ship_id: string;
  city_id: string;
};

export type AnchorEvent = {
  type: "ANCHOR";
  faction: Faction;
  piece_id: string;
  is_anchored: boolean;
};

export type PlaceEvent = {
  type: "PLACE";
  faction: Faction;
  tray_piece_id: string;
  city_id: string | null;
  target: Coordinate;
};

export type BombardEvent = {
  type: "BOMBARD";
  coord: Coordinate;
  attacking_pieces: { piece_id: string; piece_type: PieceType; faction: Faction }[];
  target: { piece_id: string; piece_type: PieceType; faction: Faction };
  attack_strength: number;
  target_strength: number;
  is_destroyed: boolean;
};

export type ShipLostTetherEvent = {
  type: "SHIP_LOST_TETHER";
  faction: Faction;
  piece_id: string;
};

export type BattleCollisionEvent = {
  type: "BATTLE_COLLISION";
  coord: Coordinate;
  entering_participants: { piece_id: string; piece_type: PieceType; faction: Faction }[];
  defending_participant: { piece_id: string; piece_type: PieceType; faction: Faction } | null;
  supporting_participants: { piece_id: string; piece_type: PieceType; faction: Faction }[];
  supporting_bombardments: { piece_id: string; piece_type: PieceType; faction: Faction }[];
  calculated_strengths: { faction: Faction; strength: number }[];
  winning_faction: Faction;
  result: "CAPTURE" | "DESTROY";
};

export type PieceAcquiredEvent = {
  type: "PIECE_ACQUIRED";
  faction: Faction;
  piece_type: PieceType;
  new_piece_id: string;
};

export type CityCapturedEvent = {
  type: "CITY_CAPTURED";
  city_id: string;
  from_faction: Faction;
  to_faction: Faction;
};

export type ShipDestroyedInBattleEvent = {
  type: "SHIP_DESTROYED_IN_BATTLE";
  piece_id: string;
  piece_type: PieceType;
  faction: Faction;
};

export type ShipDestroyedInBombardmentEvent = {
  type: "SHIP_DESTROYED_IN_BOMBARDMENT";
  piece_id: string;
  piece_type: PieceType;
  faction: Faction;
};

export type FactionEliminatedEvent = {
  type: "FACTION_ELIMINATED";
  faction: Faction;
};

export type GameOverEvent = {
  type: "GAME_OVER";
  winner: Faction | null;
  did_someone_win: boolean;
};

export type GameEvent =
  | MoveEvent
  | TetherEvent
  | AnchorEvent
  | PlaceEvent
  | BombardEvent
  | ShipLostTetherEvent
  | BattleCollisionEvent
  | PieceAcquiredEvent
  | CityCapturedEvent
  | ShipDestroyedInBattleEvent
  | ShipDestroyedInBombardmentEvent
  | FactionEliminatedEvent
  | GameOverEvent;
