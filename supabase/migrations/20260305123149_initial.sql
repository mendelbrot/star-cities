create type "public"."faction" as enum ('RED', 'YELLOW', 'GREEN', 'CYAN', 'BLUE', 'MAGENTA');

create type "public"."game_status" as enum ('WAITING', 'STARTING', 'PLANNING', 'RESOLVING', 'FINISHED');


  create table "public"."games" (
    "id" uuid not null default gen_random_uuid(),
    "status" public.game_status not null default 'WAITING'::public.game_status,
    "turn_number" integer not null default 1,
    "player_count" integer not null default 4,
    "stars" jsonb,
    "game_parameters" jsonb not null default '{"grid_size": 9, "star_count": 6, "starting_ships": ["NEUTRINO", "NEUTRINO", "PARALLAX", "ECLIPSE"], "star_count_to_win": 3, "max_ships_per_city": 5}'::jsonb,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "winner" uuid
      );


alter table "public"."games" enable row level security;


  create table "public"."players" (
    "id" uuid not null default gen_random_uuid(),
    "game_id" uuid not null,
    "user_id" uuid,
    "is_bot" boolean not null default false,
    "bot_name" text,
    "faction" public.faction not null,
    "home_star" jsonb,
    "is_ready" boolean not null default false,
    "is_eliminated" boolean not null default false,
    "eliminated_on_turn" integer,
    "is_winner" boolean not null default false
      );


alter table "public"."players" enable row level security;


  create table "public"."turn_events" (
    "id" uuid not null default gen_random_uuid(),
    "game_id" uuid not null,
    "turn_number" integer not null,
    "events" jsonb not null default '[]'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."turn_events" enable row level security;


  create table "public"."turn_planned_actions" (
    "id" uuid not null default gen_random_uuid(),
    "game_id" uuid not null,
    "player_id" uuid not null,
    "turn_number" integer not null,
    "actions" jsonb not null default '[]'::jsonb,
    "submitted_at" timestamp with time zone not null default now()
      );


alter table "public"."turn_planned_actions" enable row level security;


  create table "public"."turn_states" (
    "id" uuid not null default gen_random_uuid(),
    "game_id" uuid not null,
    "turn_number" integer not null,
    "state" jsonb not null default '[]'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."turn_states" enable row level security;


  create table "public"."user_profiles" (
    "id" uuid not null,
    "username" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_profiles" enable row level security;

CREATE UNIQUE INDEX games_pkey ON public.games USING btree (id);

CREATE UNIQUE INDEX idx_unique_human_player_per_game ON public.players USING btree (game_id, user_id) WHERE (user_id IS NOT NULL);

CREATE UNIQUE INDEX players_game_id_faction_key ON public.players USING btree (game_id, faction);

CREATE UNIQUE INDEX players_pkey ON public.players USING btree (id);

CREATE UNIQUE INDEX turn_events_game_id_turn_number_key ON public.turn_events USING btree (game_id, turn_number);

CREATE UNIQUE INDEX turn_events_pkey ON public.turn_events USING btree (id);

CREATE UNIQUE INDEX turn_planned_actions_game_id_player_id_turn_number_key ON public.turn_planned_actions USING btree (game_id, player_id, turn_number);

CREATE UNIQUE INDEX turn_planned_actions_pkey ON public.turn_planned_actions USING btree (id);

CREATE UNIQUE INDEX turn_states_game_id_turn_number_key ON public.turn_states USING btree (game_id, turn_number);

CREATE UNIQUE INDEX turn_states_pkey ON public.turn_states USING btree (id);

CREATE UNIQUE INDEX user_profiles_pkey ON public.user_profiles USING btree (id);

CREATE UNIQUE INDEX user_profiles_username_key ON public.user_profiles USING btree (username);

alter table "public"."games" add constraint "games_pkey" PRIMARY KEY using index "games_pkey";

alter table "public"."players" add constraint "players_pkey" PRIMARY KEY using index "players_pkey";

alter table "public"."turn_events" add constraint "turn_events_pkey" PRIMARY KEY using index "turn_events_pkey";

alter table "public"."turn_planned_actions" add constraint "turn_planned_actions_pkey" PRIMARY KEY using index "turn_planned_actions_pkey";

alter table "public"."turn_states" add constraint "turn_states_pkey" PRIMARY KEY using index "turn_states_pkey";

alter table "public"."user_profiles" add constraint "user_profiles_pkey" PRIMARY KEY using index "user_profiles_pkey";

alter table "public"."games" add constraint "games_winner_fkey" FOREIGN KEY (winner) REFERENCES public.players(id) not valid;

alter table "public"."games" validate constraint "games_winner_fkey";

alter table "public"."players" add constraint "player_identity" CHECK ((((is_bot = false) AND (user_id IS NOT NULL)) OR ((is_bot = true) AND (user_id IS NULL)))) not valid;

alter table "public"."players" validate constraint "player_identity";

alter table "public"."players" add constraint "players_game_id_faction_key" UNIQUE using index "players_game_id_faction_key";

alter table "public"."players" add constraint "players_game_id_fkey" FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE not valid;

alter table "public"."players" validate constraint "players_game_id_fkey";

alter table "public"."players" add constraint "players_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."players" validate constraint "players_user_id_fkey";

alter table "public"."turn_events" add constraint "turn_events_game_id_fkey" FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE not valid;

alter table "public"."turn_events" validate constraint "turn_events_game_id_fkey";

alter table "public"."turn_events" add constraint "turn_events_game_id_turn_number_key" UNIQUE using index "turn_events_game_id_turn_number_key";

alter table "public"."turn_planned_actions" add constraint "turn_planned_actions_game_id_fkey" FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE not valid;

alter table "public"."turn_planned_actions" validate constraint "turn_planned_actions_game_id_fkey";

alter table "public"."turn_planned_actions" add constraint "turn_planned_actions_game_id_player_id_turn_number_key" UNIQUE using index "turn_planned_actions_game_id_player_id_turn_number_key";

alter table "public"."turn_planned_actions" add constraint "turn_planned_actions_player_id_fkey" FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE not valid;

alter table "public"."turn_planned_actions" validate constraint "turn_planned_actions_player_id_fkey";

alter table "public"."turn_states" add constraint "turn_states_game_id_fkey" FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE not valid;

alter table "public"."turn_states" validate constraint "turn_states_game_id_fkey";

alter table "public"."turn_states" add constraint "turn_states_game_id_turn_number_key" UNIQUE using index "turn_states_game_id_turn_number_key";

alter table "public"."user_profiles" add constraint "user_profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_profiles" validate constraint "user_profiles_id_fkey";

alter table "public"."user_profiles" add constraint "user_profiles_username_key" UNIQUE using index "user_profiles_username_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.check_game_full_and_start()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

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

CREATE OR REPLACE FUNCTION public.handle_auth_user_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

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

CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object('username', NEW.username)
  WHERE id = NEW.id
    AND (raw_user_meta_data->>'username' IS DISTINCT FROM NEW.username);

  RETURN NEW;
END;
$function$
;

grant delete on table "public"."games" to "anon";

grant insert on table "public"."games" to "anon";

grant references on table "public"."games" to "anon";

grant select on table "public"."games" to "anon";

grant trigger on table "public"."games" to "anon";

grant truncate on table "public"."games" to "anon";

grant update on table "public"."games" to "anon";

grant delete on table "public"."games" to "authenticated";

grant insert on table "public"."games" to "authenticated";

grant references on table "public"."games" to "authenticated";

grant select on table "public"."games" to "authenticated";

grant trigger on table "public"."games" to "authenticated";

grant truncate on table "public"."games" to "authenticated";

grant update on table "public"."games" to "authenticated";

grant delete on table "public"."games" to "service_role";

grant insert on table "public"."games" to "service_role";

grant references on table "public"."games" to "service_role";

grant select on table "public"."games" to "service_role";

grant trigger on table "public"."games" to "service_role";

grant truncate on table "public"."games" to "service_role";

grant update on table "public"."games" to "service_role";

grant delete on table "public"."players" to "anon";

grant insert on table "public"."players" to "anon";

grant references on table "public"."players" to "anon";

grant select on table "public"."players" to "anon";

grant trigger on table "public"."players" to "anon";

grant truncate on table "public"."players" to "anon";

grant update on table "public"."players" to "anon";

grant delete on table "public"."players" to "authenticated";

grant insert on table "public"."players" to "authenticated";

grant references on table "public"."players" to "authenticated";

grant select on table "public"."players" to "authenticated";

grant trigger on table "public"."players" to "authenticated";

grant truncate on table "public"."players" to "authenticated";

grant update on table "public"."players" to "authenticated";

grant delete on table "public"."players" to "service_role";

grant insert on table "public"."players" to "service_role";

grant references on table "public"."players" to "service_role";

grant select on table "public"."players" to "service_role";

grant trigger on table "public"."players" to "service_role";

grant truncate on table "public"."players" to "service_role";

grant update on table "public"."players" to "service_role";

grant delete on table "public"."turn_events" to "anon";

grant insert on table "public"."turn_events" to "anon";

grant references on table "public"."turn_events" to "anon";

grant select on table "public"."turn_events" to "anon";

grant trigger on table "public"."turn_events" to "anon";

grant truncate on table "public"."turn_events" to "anon";

grant update on table "public"."turn_events" to "anon";

grant delete on table "public"."turn_events" to "authenticated";

grant insert on table "public"."turn_events" to "authenticated";

grant references on table "public"."turn_events" to "authenticated";

grant select on table "public"."turn_events" to "authenticated";

grant trigger on table "public"."turn_events" to "authenticated";

grant truncate on table "public"."turn_events" to "authenticated";

grant update on table "public"."turn_events" to "authenticated";

grant delete on table "public"."turn_events" to "service_role";

grant insert on table "public"."turn_events" to "service_role";

grant references on table "public"."turn_events" to "service_role";

grant select on table "public"."turn_events" to "service_role";

grant trigger on table "public"."turn_events" to "service_role";

grant truncate on table "public"."turn_events" to "service_role";

grant update on table "public"."turn_events" to "service_role";

grant delete on table "public"."turn_planned_actions" to "anon";

grant insert on table "public"."turn_planned_actions" to "anon";

grant references on table "public"."turn_planned_actions" to "anon";

grant select on table "public"."turn_planned_actions" to "anon";

grant trigger on table "public"."turn_planned_actions" to "anon";

grant truncate on table "public"."turn_planned_actions" to "anon";

grant update on table "public"."turn_planned_actions" to "anon";

grant delete on table "public"."turn_planned_actions" to "authenticated";

grant insert on table "public"."turn_planned_actions" to "authenticated";

grant references on table "public"."turn_planned_actions" to "authenticated";

grant select on table "public"."turn_planned_actions" to "authenticated";

grant trigger on table "public"."turn_planned_actions" to "authenticated";

grant truncate on table "public"."turn_planned_actions" to "authenticated";

grant update on table "public"."turn_planned_actions" to "authenticated";

grant delete on table "public"."turn_planned_actions" to "service_role";

grant insert on table "public"."turn_planned_actions" to "service_role";

grant references on table "public"."turn_planned_actions" to "service_role";

grant select on table "public"."turn_planned_actions" to "service_role";

grant trigger on table "public"."turn_planned_actions" to "service_role";

grant truncate on table "public"."turn_planned_actions" to "service_role";

grant update on table "public"."turn_planned_actions" to "service_role";

grant delete on table "public"."turn_states" to "anon";

grant insert on table "public"."turn_states" to "anon";

grant references on table "public"."turn_states" to "anon";

grant select on table "public"."turn_states" to "anon";

grant trigger on table "public"."turn_states" to "anon";

grant truncate on table "public"."turn_states" to "anon";

grant update on table "public"."turn_states" to "anon";

grant delete on table "public"."turn_states" to "authenticated";

grant insert on table "public"."turn_states" to "authenticated";

grant references on table "public"."turn_states" to "authenticated";

grant select on table "public"."turn_states" to "authenticated";

grant trigger on table "public"."turn_states" to "authenticated";

grant truncate on table "public"."turn_states" to "authenticated";

grant update on table "public"."turn_states" to "authenticated";

grant delete on table "public"."turn_states" to "service_role";

grant insert on table "public"."turn_states" to "service_role";

grant references on table "public"."turn_states" to "service_role";

grant select on table "public"."turn_states" to "service_role";

grant trigger on table "public"."turn_states" to "service_role";

grant truncate on table "public"."turn_states" to "service_role";

grant update on table "public"."turn_states" to "service_role";

grant delete on table "public"."user_profiles" to "anon";

grant insert on table "public"."user_profiles" to "anon";

grant references on table "public"."user_profiles" to "anon";

grant select on table "public"."user_profiles" to "anon";

grant trigger on table "public"."user_profiles" to "anon";

grant truncate on table "public"."user_profiles" to "anon";

grant update on table "public"."user_profiles" to "anon";

grant delete on table "public"."user_profiles" to "authenticated";

grant insert on table "public"."user_profiles" to "authenticated";

grant references on table "public"."user_profiles" to "authenticated";

grant select on table "public"."user_profiles" to "authenticated";

grant trigger on table "public"."user_profiles" to "authenticated";

grant truncate on table "public"."user_profiles" to "authenticated";

grant update on table "public"."user_profiles" to "authenticated";

grant delete on table "public"."user_profiles" to "service_role";

grant insert on table "public"."user_profiles" to "service_role";

grant references on table "public"."user_profiles" to "service_role";

grant select on table "public"."user_profiles" to "service_role";

grant trigger on table "public"."user_profiles" to "service_role";

grant truncate on table "public"."user_profiles" to "service_role";

grant update on table "public"."user_profiles" to "service_role";


  create policy "Authenticated users can create games"
  on "public"."games"
  as permissive
  for insert
  to authenticated
with check (((status = 'WAITING'::public.game_status) AND (turn_number = 1)));



  create policy "Authenticated users can see all games"
  on "public"."games"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Authenticated users can add player bots to games"
  on "public"."players"
  as permissive
  for insert
  to authenticated
with check (((is_bot = true) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



  create policy "Authenticated users can join games"
  on "public"."players"
  as permissive
  for insert
  to authenticated
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



  create policy "Authenticated users can remove player bots from games"
  on "public"."players"
  as permissive
  for delete
  to authenticated
using (((is_bot = true) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



  create policy "Authenticated users can see all players"
  on "public"."players"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Authenticated users can update player bot data"
  on "public"."players"
  as permissive
  for update
  to authenticated
using (((is_bot = true) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



  create policy "Players can leave games"
  on "public"."players"
  as permissive
  for delete
  to authenticated
using (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



  create policy "Players can update their own data"
  on "public"."players"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id));



  create policy "Authenticated users can see all turn events"
  on "public"."turn_events"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Authenticated users can see all planned actions"
  on "public"."turn_planned_actions"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Players can delete their own actions"
  on "public"."turn_planned_actions"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.players
     JOIN public.games ON ((games.id = players.game_id)))
  WHERE ((players.id = turn_planned_actions.player_id) AND (players.user_id = auth.uid()) AND (games.status = 'PLANNING'::public.game_status) AND (games.turn_number = turn_planned_actions.turn_number)))));



  create policy "Players can insert their own actions"
  on "public"."turn_planned_actions"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM (public.players
     JOIN public.games ON ((games.id = players.game_id)))
  WHERE ((players.id = turn_planned_actions.player_id) AND (players.user_id = auth.uid()) AND (games.status = 'PLANNING'::public.game_status) AND (games.turn_number = turn_planned_actions.turn_number)))));



  create policy "Players can update their own actions"
  on "public"."turn_planned_actions"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.players
     JOIN public.games ON ((games.id = players.game_id)))
  WHERE ((players.id = turn_planned_actions.player_id) AND (players.user_id = auth.uid()) AND (games.status = 'PLANNING'::public.game_status) AND (games.turn_number = turn_planned_actions.turn_number)))));



  create policy "Authenticated users can see all turn states"
  on "public"."turn_states"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Anyone can view user profiles"
  on "public"."user_profiles"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Users can insert their own profile"
  on "public"."user_profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = id));



  create policy "Users can update their own profile"
  on "public"."user_profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = id));


CREATE TRIGGER trigger_check_game_full AFTER INSERT ON public.players FOR EACH ROW EXECUTE FUNCTION public.check_game_full_and_start();

CREATE TRIGGER trigger_delete_abandoned_game AFTER DELETE ON public.players FOR EACH ROW EXECUTE FUNCTION public.delete_abandoned_game();

CREATE TRIGGER trigger_resolve_turn AFTER UPDATE OF is_ready ON public.players FOR EACH ROW EXECUTE FUNCTION public.handle_player_ready();

CREATE TRIGGER trigger_sync_user_profile_to_auth AFTER UPDATE OF username ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.handle_user_profile_update();

CREATE TRIGGER trigger_sync_user_profile AFTER INSERT OR UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_auth_user_update();


