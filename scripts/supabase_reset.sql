TRUNCATE auth.users CASCADE;
TRUNCATE auth.audit_log_entries;
TRUNCATE supabase_migrations.schema_migrations;
TRUNCATE supabase_functions.hooks;
TRUNCATE supabase_functions.migrations;
TRUNCATE net._http_response;
TRUNCATE realtime.messages;
TRUNCATE realtime.schema_migrations;
TRUNCATE realtime.subscription;

DROP SCHEMA public CASCADE;

CREATE SCHEMA public;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;