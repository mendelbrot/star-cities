-- 1. Trigger to automatically set game status to 'STARTING' when the player count is reached.
CREATE OR REPLACE FUNCTION check_game_full_and_start()
RETURNS TRIGGER AS $$
DECLARE
    target_count INTEGER;
    current_count INTEGER;
BEGIN
    -- Get the target player count from the game record
    SELECT player_count INTO target_count FROM games WHERE id = NEW.game_id;
    
    -- Count how many players have joined this game
    SELECT COUNT(*) INTO current_count FROM players WHERE game_id = NEW.game_id;
    
    -- If the counts match, update the game status to 'STARTING'
    IF current_count = target_count THEN
        UPDATE games SET status = 'STARTING' WHERE id = NEW.game_id AND status = 'WAITING';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_check_game_full
AFTER INSERT ON players
FOR EACH ROW
EXECUTE FUNCTION check_game_full_and_start();
