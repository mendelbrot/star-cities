-- Consolidated script for settings not captured by 'supabase db diff'.
-- This includes Publication management, Replica Identity, and View Grants.

-- 1. REALTIME PUBLICATION
-- 'SET TABLE' replaces the entire list of tables in the publication.
-- This is cleaner and more idempotent than adding/dropping individual tables.
ALTER PUBLICATION supabase_realtime SET TABLE 
    user_profiles, 
    games, 
    players, 
    turn_states, 
    turn_planned_actions, 
    turn_events;


-- 2. REPLICA IDENTITY (Required for Deletion events)
ALTER TABLE user_profiles REPLICA IDENTITY FULL;
ALTER TABLE games REPLICA IDENTITY FULL;
ALTER TABLE players REPLICA IDENTITY FULL;
ALTER TABLE turn_states REPLICA IDENTITY FULL;
ALTER TABLE turn_planned_actions REPLICA IDENTITY FULL;
ALTER TABLE turn_events REPLICA IDENTITY FULL;


-- 3. VIEW GRANTS
-- Grants for authenticated users to access views.
GRANT SELECT ON v_user_game_status TO authenticated;
GRANT SELECT ON v_user_game_status TO anon;
GRANT SELECT ON v_user_game_status TO service_role;
