import postgres from "https://deno.land/x/postgresjs@v3.3.3/mod.js";

const dbUrl = Deno.env.get("SUPABASE_DB_URL")!;

export const sql = postgres(dbUrl, {
  prepare: false, // Required for Supabase / PgBouncer
});
