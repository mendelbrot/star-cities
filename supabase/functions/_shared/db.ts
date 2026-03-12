import postgres from "postgres";

const dbUrl = Deno.env.get("SUPABASE_DB_URL")!;

export const sql = postgres(dbUrl, {
  prepare: false, // Required for Supabase / PgBouncer
});
