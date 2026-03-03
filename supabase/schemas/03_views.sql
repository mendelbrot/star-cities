-- View to easily query games and their relationship to users.
-- Supports the 4-list Lobby: TAP Required, TAP Done, Waiting for Players, and Open Games.

CREATE OR REPLACE VIEW v_user_game_status AS
SELECT 
    g.id AS game_id,
    g.status AS game_status,
    g.turn_number,
    g.player_count,
    g.created_at,
    p.user_id,
    p.is_ready,
    p.faction,
    p.is_eliminated,
    p.is_bot
FROM games g
LEFT JOIN players p ON g.id = p.game_id;
