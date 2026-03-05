alter table "public"."user_profiles" alter column "username" drop not null;

set check_function_bodies = off;

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


