alter table "public"."turn_events" add column "player_ranking" jsonb not null default '[]'::jsonb;


