export type Faction = "BLUE" | "RED" | "PURPLE" | "GREEN";
export type PieceType = "STAR_CITY" | "NEUTRINO" | "ECLIPSE" | "PARALLAX";

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
  is_stunned: boolean;
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
