create or replace view "public"."v_user_game_status" as  SELECT g.id AS game_id,
    g.status AS game_status,
    g.turn_number,
    p.user_id,
    p.is_ready,
    p.faction,
    p.is_eliminated,
    p.is_bot
   FROM (public.games g
     LEFT JOIN public.players p ON ((g.id = p.game_id)));



