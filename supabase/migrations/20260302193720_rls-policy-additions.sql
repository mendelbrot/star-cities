
  create policy "Authenticated users can add player bots to games"
  on "public"."players"
  as permissive
  for insert
  to authenticated
with check (((is_bot = true) AND (EXISTS ( SELECT 1
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



  create policy "Players can leave games"
  on "public"."players"
  as permissive
  for delete
  to authenticated
using (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.games
  WHERE ((games.id = players.game_id) AND (games.status = 'WAITING'::public.game_status))))));



