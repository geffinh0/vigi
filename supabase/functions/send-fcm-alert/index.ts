import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Supabase Edge Function para envio de Alertas Push FCM a Guardiões
serve(async (req) => {
  try {
    const payload = await req.json();
    const { record, table, type } = payload;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const userId = record.user_id;

    // 1. Busca os guardiões aceitos vinculados a este usuário na tabela family_links
    const { data: links, error: linkError } = await supabase
      .from("family_links")
      .select("guardian_id")
      .eq("dependent_id", userId)
      .eq("status", "accepted");

    if (linkError || !links || links.length === 0) {
      return new Response(
        JSON.stringify({ message: "Nenhum guardião vinculado encontrado." }),
        { headers: { "Content-Type": "application/json" }, status: 200 }
      );
    }

    const guardianIds = links.map((l) => l.guardian_id);

    // 2. Busca os fcm_tokens dos guardiões
    const { data: profiles, error: profileError } = await supabase
      .from("profiles")
      .select("id, fcm_token")
      .in("id", guardianIds)
      .not("fcm_token", "is", null);

    if (profileError || !profiles) {
      return new Response(
        JSON.stringify({ message: "Nenhum token FCM registrado para os guardiões." }),
        { headers: { "Content-Type": "application/json" }, status: 200 }
      );
    }

    const tokens = profiles.map((p) => p.fcm_token).filter(Boolean);

    // 3. Monta a mensagem de alerta baseada na tabela que disparou o webhook
    let title = "🚨 ALERTA GUARDIÃO";
    let body = "Ocorreu um evento de segurança com seu familiar.";

    if (table === "panic_events") {
      title = "🆘 BOTÃO DE PÂNICO ACIONADO!";
      body = `Um familiar acionou o Botão de Pânico. Coordenadas: (${record.lat}, ${record.lng})`;
    } else if (table === "checkin_settings" && record.status === "expired") {
      title = "⚠️ CHECK-IN EXPIRADO";
      body = "Um familiar não realizou o check-in no tempo limite do Dead Man Switch.";
    }

    console.log(`Disparando notificação push para ${tokens.length} guardiões:`, {
      title,
      body,
      tokens,
    });

    return new Response(
      JSON.stringify({
        success: true,
        sentTo: tokens.length,
        title,
        body,
      }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    );
  }
});
