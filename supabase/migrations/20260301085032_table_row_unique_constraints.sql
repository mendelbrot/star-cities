CREATE UNIQUE INDEX turn_planned_actions_game_id_player_id_turn_number_key ON public.turn_planned_actions USING btree (game_id, player_id, turn_number);

alter table "public"."turn_planned_actions" add constraint "turn_planned_actions_game_id_player_id_turn_number_key" UNIQUE using index "turn_planned_actions_game_id_player_id_turn_number_key";


