import { Faction, PlannedAction, Coordinate, Piece, Player } from "../../_shared/types.ts";
import { isSameCoordinate, getAdjacentCoordinates, getTorusDistance } from "../../_shared/map.ts";
import { TurnContext } from "../context.ts";
import { MAX_TETHERED_SHIPS, TETHER_RANGE } from "../constants.ts";

export function resolveIntents(
  context: TurnContext, 
  plannedActions: { player_id: string; actions: PlannedAction[] }[],
  factionMoveTargetsMap: Map<string, Set<string>>
) {
  context.currentStep = 1;
  const { params, stars, players, pieceMap, coordinateMap, factionPlacedPiecesMap, tetherMap, pieceContexts } = context;
  const size = params.grid_size;

  for (const playerActionRow of plannedActions) {
    const player = players.find((p: Player) => p.id === playerActionRow.player_id);
    if (!player) continue;

    for (const action of playerActionRow.actions) {
      if (action.type === "PLACE_ACT") {
        const piece = pieceMap.get(action.tray_piece_id);
        if (!piece || !piece.is_in_tray || piece.faction !== player.faction) continue;

        const targetKey = `${action.target.x},${action.target.y}`;
        const isStar = stars.some((s: Coordinate) => isSameCoordinate(s, action.target));
        const isOccupiedAtStart = coordinateMap.has(targetKey);
        const isMoveTarget = factionMoveTargetsMap.get(player.faction)?.has(targetKey);
        
        // Block if star, occupied at start, or friendly move target
        if (isStar || isOccupiedAtStart || isMoveTarget) continue;

        // Block if another friendly piece is already being placed here
        const existingPlacements = context.pendingPlacements.get(targetKey) || [];
        const isFriendlyPlacing = existingPlacements.some(id => pieceMap.get(id)?.faction === player.faction);
        if (isFriendlyPlacing) continue;

        let isNearValidCity = false;
        if (piece.type === "ECLIPSE" || piece.type === "PARALLAX") {
          if (!action.city_id) continue;
          const city = pieceMap.get(action.city_id);
          if (!city || city.type !== "STAR_CITY" || city.faction !== player.faction || !city.is_anchored) continue;
          
          const tetheredCount = tetherMap.get(city.id)?.length || 0;
          if (tetheredCount >= MAX_TETHERED_SHIPS) continue;

          const adj = getAdjacentCoordinates(city as Coordinate, size);
          isNearValidCity = adj.some((a: Coordinate) => isSameCoordinate(a, action.target));
        } else {
          const factionCities = (factionPlacedPiecesMap.get(player.faction) || [])
            .map((id: string) => pieceMap.get(id)!)
            .filter((p: Piece) => p.type === "STAR_CITY" && p.is_anchored);
          
          isNearValidCity = factionCities.some((city: Piece) => {
            const adj = getAdjacentCoordinates(city as Coordinate, size);
            return adj.some((a: Coordinate) => isSameCoordinate(a, action.target));
          });
        }

        if (!isNearValidCity) continue;

        // IMPORTANT: We do NOT update the coordinateMap yet.
        // We only set the piece's coordinates and add to pending placements.
        piece.x = action.target.x;
        piece.y = action.target.y;
        
        const pending = context.pendingPlacements.get(targetKey) || [];
        pending.push(piece.id);
        context.pendingPlacements.set(targetKey, pending);

        if (piece.type === "ECLIPSE" || piece.type === "PARALLAX") {
          piece.tether_id = action.city_id;
          const ships = tetherMap.get(action.city_id!) || [];
          ships.push(piece.id);
          tetherMap.set(action.city_id!, ships);
        }

        pieceContexts.set(piece.id, { wasJustPlaced: true });

        context.addEvent({
          type: "PLACE",
          faction: player.faction as Faction,
          tray_piece_id: action.tray_piece_id,
          city_id: action.city_id,
          target: action.target,
        });
      } 
      else if (action.type === "TETHER_ACT") {
        const ship = pieceMap.get(action.ship_id);
        const ctx = pieceContexts.get(action.ship_id);
        if (!ship || (ship.is_in_tray && !ctx?.wasJustPlaced) || ship.faction !== player.faction) continue;
        if (ship.type !== "ECLIPSE" && ship.type !== "PARALLAX") continue;

        const city = pieceMap.get(action.city_id);
        if (!city || city.type !== "STAR_CITY" || city.faction !== player.faction || !city.is_anchored) continue;

        const tetheredCount = tetherMap.get(city.id)?.length || 0;
        if (tetheredCount >= MAX_TETHERED_SHIPS) continue;

        const dist = getTorusDistance(ship as Coordinate, city as Coordinate, size);
        if (dist > TETHER_RANGE) continue;

        if (ship.tether_id) {
          const oldShips = tetherMap.get(ship.tether_id) || [];
          tetherMap.set(ship.tether_id, oldShips.filter(id => id !== ship.id));
        }

        ship.tether_id = action.city_id;
        const ships = tetherMap.get(action.city_id) || [];
        ships.push(ship.id);
        tetherMap.set(action.city_id, ships);

        context.addEvent({
          type: "TETHER",
          faction: player.faction as Faction,
          ship_id: action.ship_id,
          city_id: action.city_id,
        });
      } 
      else if (action.type === "ANCHOR_ACT") {
        const city = pieceMap.get(action.piece_id);
        if (!city || city.type !== "STAR_CITY" || city.is_in_tray || city.faction !== player.faction) continue;

        const ctx = pieceContexts.get(city.id) || {};
        if (ctx.wasJustPlaced) continue; // CANNOT anchor on the same turn it was placed

        if (action.is_anchored) {
          const adj = getAdjacentCoordinates(city as Coordinate, size);
          const isNearStar = adj.some(a => stars.some(s => isSameCoordinate(s, a)));
          if (!isNearStar) continue;

          const wasAnchored = city.is_anchored;
          city.is_anchored = true;
          if (!wasAnchored) {
            const ctx = pieceContexts.get(city.id) || {};
            pieceContexts.set(city.id, { ...ctx, wasJustAnchored: true });
          }
        } else {
          const tetheredCount = tetherMap.get(city.id)?.length || 0;
          if (tetheredCount > 0) continue;

          const wasAnchored = city.is_anchored;
          city.is_anchored = false;
          if (wasAnchored) {
            const ctx = pieceContexts.get(city.id) || {};
            if (ctx.wasJustAnchored) {
              pieceContexts.set(city.id, { ...ctx, wasJustAnchored: false, wasJustDeanchored: false });
            } else {
              pieceContexts.set(city.id, { ...ctx, wasJustDeanchored: true });
            }
          }
        }

        context.addEvent({
          type: "ANCHOR",
          faction: player.faction as Faction,
          piece_id: action.piece_id,
          is_anchored: city.is_anchored,
        });
      }
    }
  }
}
