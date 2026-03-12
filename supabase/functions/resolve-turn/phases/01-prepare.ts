import postgres from "postgres";
import { ServerError } from "../../_shared/server-error.ts";
import { Coordinate, Piece, PlannedAction, Player, GameParameters } from "../../_shared/types.ts";
import { TurnContext } from "../context.ts";

interface GameRow {
  status: string;
  game_parameters: GameParameters;
  stars: Coordinate[];
}

interface TurnStateRow {
  state: Piece[];
}

interface TurnPlannedActionsRow {
  player_id: string;
  actions: PlannedAction[];
}

export async function prepare(sql: postgres.Sql, game_id: string, turn_number: number): Promise<{ 
  context: TurnContext; 
  plannedActions: TurnPlannedActionsRow[];
  factionMoveTargetsMap: Map<string, Set<string>>;
}> {
  // 1. Fetch Game, Players, Current State, and Planned Actions
  const [game] = await sql<GameRow[]>`
    SELECT status, game_parameters, stars FROM games WHERE id = ${game_id} FOR UPDATE
  `;

  if (!game) {
    throw new ServerError(`Game not found: ${game_id}`, 400);
  }

  if (game.status !== "RESOLVING") {
    throw new ServerError(`Game status changed to ${game.status}.`, 400);
  }

  const players = await sql<Player[]>`
    SELECT * FROM players 
    WHERE game_id = ${game_id}
  `;

  const [currentStateRow] = await sql<TurnStateRow[]>`
    SELECT state FROM turn_states 
    WHERE game_id = ${game_id} AND turn_number = ${turn_number}
  `;

  if (!currentStateRow) {
    throw new ServerError(`Turn state not found for turn ${turn_number}`, 400);
  }

  const plannedActions = await sql<TurnPlannedActionsRow[]>`
    SELECT player_id, actions FROM turn_planned_actions 
    WHERE game_id = ${game_id} AND turn_number = ${turn_number}
  `;

  // Reset Neutrino visibility for the working state
  const initialState: Piece[] = currentStateRow.state.map((p: Piece) => ({
    ...p,
    is_visible: p.type === "NEUTRINO" ? false : true,
  }));

  const context = new TurnContext(
    game_id,
    turn_number,
    game.game_parameters,
    game.stars,
    players,
    initialState
  );

  // Pre-calculate move targets for validation
  const factionMoveTargetsMap = new Map<string, Set<string>>(); 
  for (const row of plannedActions) {
    const player = players.find((p: Player) => p.id === row.player_id);
    if (!player) continue;
    const targets = new Set<string>();
    for (const action of row.actions) {
      if (action.type === "MOVE_ACT") {
        targets.add(`${action.to.x},${action.to.y}`);
      }
    }
    factionMoveTargetsMap.set(player.faction, targets);
  }

  return { context, plannedActions, factionMoveTargetsMap };
}
