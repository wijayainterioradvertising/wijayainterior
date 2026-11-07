// Deploy as Supabase Edge Function: admin-login
// Configure secrets: ADMIN_USERNAME, ADMIN_AUTH_EMAIL
// SUPABASE_URL and SUPABASE_ANON_KEY are available as Supabase function environment variables.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  try {
    const { username, password } = await req.json();
    const expectedUsername = Deno.env.get("ADMIN_USERNAME") ?? "";
    const adminEmail = Deno.env.get("ADMIN_AUTH_EMAIL") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!expectedUsername || !adminEmail || !supabaseUrl || !anonKey) {
      return new Response(JSON.stringify({ error: "Konfigurasi login admin belum lengkap." }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    if (typeof username !== "string" || typeof password !== "string" ||
        username !== expectedUsername || password.length < 1 || password.length > 256) {
      return new Response(JSON.stringify({ error: "Username atau password tidak sesuai." }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const authClient = createClient(supabaseUrl, anonKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data, error } = await authClient.auth.signInWithPassword({ email: adminEmail, password });
    if (error || !data.session) {
      return new Response(JSON.stringify({ error: "Username atau password tidak sesuai." }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    return new Response(JSON.stringify({ session: data.session }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (_err) {
    return new Response(JSON.stringify({ error: "Permintaan login tidak dapat diproses." }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
