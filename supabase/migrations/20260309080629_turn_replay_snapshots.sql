alter table "public"."turn_events" add column "snapshots" jsonb not null default '{}'::jsonb;


