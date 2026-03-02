set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.delete_abandoned_game()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE TRIGGER trigger_delete_abandoned_game AFTER DELETE ON public.players FOR EACH ROW EXECUTE FUNCTION public.delete_abandoned_game();


