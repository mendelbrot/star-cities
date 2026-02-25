-- Enable RLS for all tables
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE turn_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE turn_planned_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE turn_events ENABLE ROW LEVEL SECURITY;

-- Games policies
CREATE POLICY "Authenticated users can see all games" ON games
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can create games" ON games
    FOR INSERT TO authenticated WITH CHECK (true);

-- Players policies
CREATE POLICY "Authenticated users can see all players" ON players
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can join games" ON players
    FOR INSERT TO authenticated WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM games
            WHERE games.id = game_id
            AND games.status = 'WAITING'
        )
    );

CREATE POLICY "Players can update their own data" ON players
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Turn States policies
CREATE POLICY "Authenticated users can see all turn states" ON turn_states
    FOR SELECT TO authenticated USING (true);

-- Turn Planned Actions policies
CREATE POLICY "Authenticated users can see all planned actions" ON turn_planned_actions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Players can insert their own actions" ON turn_planned_actions
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM players
            JOIN games ON games.id = players.game_id
            WHERE players.id = turn_planned_actions.player_id
            AND players.user_id = auth.uid()
            AND games.status = 'PLANNING'
            AND games.turn_number = turn_planned_actions.turn_number
        )
    );

CREATE POLICY "Players can update their own actions" ON turn_planned_actions
    FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM players
            JOIN games ON games.id = players.game_id
            WHERE players.id = turn_planned_actions.player_id
            AND players.user_id = auth.uid()
            AND games.status = 'PLANNING'
            AND games.turn_number = turn_planned_actions.turn_number
        )
    );

CREATE POLICY "Players can delete their own actions" ON turn_planned_actions
    FOR DELETE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM players
            JOIN games ON games.id = players.game_id
            WHERE players.id = turn_planned_actions.player_id
            AND players.user_id = auth.uid()
            AND games.status = 'PLANNING'
            AND games.turn_number = turn_planned_actions.turn_number
        )
    );

-- Turn Events policies
CREATE POLICY "Authenticated users can see all turn events" ON turn_events
    FOR SELECT TO authenticated USING (true);
