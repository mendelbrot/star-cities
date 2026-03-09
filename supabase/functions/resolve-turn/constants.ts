import { PieceType } from "../_shared/types.ts";

export const MAX_TETHERED_SHIPS = 5;
export const TETHER_RANGE = 2;
export const BOMBARD_RANGE = 2;
export const BOMBARD_STRENGTH = 2;
export const SUPPORT_STRENGTH_FACTOR = 0.5;
export const BOMBARD_SUPPORT_STRENGTH = 1.0;
export const MAX_TRAY_SIZE = 5;

export const UNIT_STRENGTH: Record<PieceType, number> = {
  STAR_CITY: 8,
  NEUTRINO: 2,
  ECLIPSE: 4,
  PARALLAX: 6,
};

export const UNIT_MOVEMENT: Record<PieceType, number> = {
  STAR_CITY: 1,
  NEUTRINO: 1,
  ECLIPSE: 1,
  PARALLAX: 2,
};

export const ACQUISITION_PROBABILITIES = {
  NEUTRINO: 0.25,
  ECLIPSE: 0.20,
  PARALLAX: 0.20,
  STAR_CITY: 0.10,
  NOTHING: 0.25,
};
