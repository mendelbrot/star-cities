set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_auth_user_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Sync the metadata to the profile table
    -- Using the metadata stored in 'raw_user_meta_data'
    INSERT INTO public.user_profiles (id, username, profile_icon)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'Unknown'),
        COALESCE(NEW.raw_user_meta_data->>'profile_icon', 'default_icon')
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        profile_icon = EXCLUDED.profile_icon,
        updated_at = NOW();

    RETURN NEW;
END;
$function$
;

CREATE TRIGGER trigger_sync_user_profile AFTER INSERT OR UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_auth_user_update();


