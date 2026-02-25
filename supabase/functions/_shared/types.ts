export type Faction = "BLUE" | "RED" | "PURPLE" | "GREEN";

export interface GameParameters {
  grid_size: number;
  star_count: number;
  star_count_to_win: number;
  max_ships_per_city: number;
  starting_ships: string[];
}

export interface Coordinate {
  x: number;
  y: number;
}

export interface Piece {
  id: string;
  faction: Faction;
  type: "STAR_CITY" | "NEUTRINO" | "ECLIPSE" | "PARALLAX";
  x: number | null;
  y: number | null;
  tether_id: string | null;
  is_anchored: boolean;
  is_stunned: boolean;
  is_visible: boolean;
  is_in_tray: boolean;
}
