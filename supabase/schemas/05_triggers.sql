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

-- 3. Trigger to delete the game if the last human player leaves.
CREATE OR REPLACE FUNCTION delete_abandoned_game()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act if the deleted player was a human (is_bot = FALSE)
    -- and the game still exists (to avoid recursion or errors during game deletion)
    IF OLD.is_bot = FALSE THEN
        IF NOT EXISTS (
            SELECT 1 FROM players 
            WHERE game_id = OLD.game_id 
              AND is_bot = FALSE
        ) THEN
            DELETE FROM games WHERE id = OLD.game_id;
        END IF;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_delete_abandoned_game
AFTER DELETE ON players
FOR EACH ROW
EXECUTE FUNCTION delete_abandoned_game();

-- 4. Sync Auth User Metadata -> public.user_profiles
CREATE OR REPLACE FUNCTION handle_auth_user_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, username)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'username'
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        updated_at = NOW()
    WHERE user_profiles.username IS DISTINCT FROM EXCLUDED.username;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on the 'auth.users' table
CREATE TRIGGER trigger_sync_user_profile
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_auth_user_update();

-- 5. Sync public.user_profiles -> Auth User Metadata
CREATE OR REPLACE FUNCTION handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object('username', NEW.username)
  WHERE id = NEW.id
    AND (raw_user_meta_data->>'username' IS DISTINCT FROM NEW.username);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on the 'public.user_profiles' table
CREATE TRIGGER trigger_sync_user_profile_to_auth
AFTER UPDATE OF username ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION handle_user_profile_update();
