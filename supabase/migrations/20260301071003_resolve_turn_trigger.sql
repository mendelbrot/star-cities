drop policy "Authenticated users can create games" on "public"."games";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_player_ready()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;


  create policy "Authenticated users can create games"
  on "public"."games"
  as permissive
  for insert
  to authenticated
with check (((status = 'WAITING'::public.game_status) AND (turn_number = 1)));


CREATE TRIGGER trigger_resolve_turn AFTER UPDATE OF is_ready ON public.players FOR EACH ROW EXECUTE FUNCTION public.handle_player_ready();


