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
  x: number | null;
  y: number | null;
  tether_id: string | null;
  is_anchored: boolean;
  is_stunned: boolean;
  is_visible: boolean;
  is_in_tray: boolean;
};
