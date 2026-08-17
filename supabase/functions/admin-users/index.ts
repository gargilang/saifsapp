import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── Autentikasi caller ────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Client untuk verifikasi caller (pakai JWT caller)
  const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user: caller },
    error: userErr,
  } = await callerClient.auth.getUser();

  if (userErr || !caller) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Verifikasi caller adalah admin
  const { data: profile } = await callerClient
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .single();

  if (profile?.role !== "admin") {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Admin client untuk operasi privileged
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // ── Router ───────────────────────────────────────────────────────────────
  try {
    if (req.method === "GET") {
      const { data: profiles, error } = await adminClient
        .from("profiles")
        .select("id, display_name, created_at")
        .eq("role", "admin");

      if (error) throw error;

      const admins = await Promise.all(
        (profiles ?? []).map(async (p) => {
          const {
            data: { user },
          } = await adminClient.auth.admin.getUserById(p.id);
          return {
            id: p.id,
            email: user?.email ?? "",
            display_name: p.display_name,
            created_at: p.created_at,
          };
        })
      );

      return new Response(JSON.stringify({ admins }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST") {
      const { email, password, display_name } = await req.json();

      if (!email || !password || !display_name) {
        return new Response(
          JSON.stringify({
            error: "email, password, display_name wajib diisi",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      if (password.length < 6) {
        return new Response(
          JSON.stringify({ error: "Password minimal 6 karakter" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { data, error } = await adminClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name },
      });

      if (error) {
        const status = error.message.toLowerCase().includes("already") ? 409 : 400;
        return new Response(JSON.stringify({ error: error.message }), {
          status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(
        JSON.stringify({
          id: data.user.id,
          email: data.user.email,
          display_name,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (req.method === "DELETE") {
      const { user_id } = await req.json();

      if (!user_id) {
        return new Response(
          JSON.stringify({ error: "user_id wajib diisi" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      if (user_id === caller.id) {
        return new Response(
          JSON.stringify({ error: "Tidak bisa menghapus akun sendiri" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { error } = await adminClient.auth.admin.deleteUser(user_id);
      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
