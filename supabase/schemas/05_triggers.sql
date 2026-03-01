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

-- 2. Trigger to automatically set game status to 'RESOLVING' when all non-eliminated players are ready.
CREATE OR REPLACE FUNCTION handle_player_ready()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act if is_ready changed to true
    IF (NEW.is_ready = true AND (OLD.is_ready = false OR OLD.is_ready IS NULL)) THEN
        -- Check if all active (non-eliminated) players in this game are ready
        IF NOT EXISTS (
            SELECT 1 FROM players 
            WHERE game_id = NEW.game_id 
              AND is_eliminated = false 
              AND is_ready = false
        ) THEN
            -- Update game status to 'RESOLVING' to trigger the resolve-turn edge function
            UPDATE games 
            SET status = 'RESOLVING' 
            WHERE id = NEW.game_id 
              AND status = 'PLANNING';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_resolve_turn
AFTER UPDATE OF is_ready ON players
FOR EACH ROW
EXECUTE FUNCTION handle_player_ready();
