// Edge Function: notify-emergency-contacts
// Disparada quando um checkin_events do tipo 'panic' ou 'alert_triggered' é inserido.
// ADR-001 (Canal 2: Alerta remoto via FCM para familiares/contatos de emergência)

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const { record } = await req.json();

    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Obter os IDs de familiares vinculados e aceitos
    const { data: viewers, error: linksError } = await supabaseAdmin
      .from("family_links")
      .select("viewer_user_id")
      .eq("monitored_user_id", record.user_id)
      .eq("status", "accepted");

    if (linksError) {
      return new Response(JSON.stringify({ error: linksError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const viewerIds = (viewers ?? []).map((v) => v.viewer_user_id);

    if (viewerIds.length === 0) {
      return new Response(
        JSON.stringify({ message: "Nenhum familiar vinculado para notificar" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Buscar tokens FCM registrados para os familiares
    const { data: deviceTokens } = await supabaseAdmin
      .from("device_tokens")
      .select("fcm_token")
      .in("user_id", viewerIds);

    const tokens = (deviceTokens ?? []).map((t) => t.fcm_token);

    // 3. Montar payload do push de emergência
    const isPanic = record.event_type === "panic";
    const title = isPanic
      ? "🚨 ALERTA DE EMERGÊNCIA — PÂNICO"
      : "⚠️ ALERTA — Prazo de Segurança Expirado";
    const body = isPanic
      ? "Um pedido de ajuda imediato foi disparado pelo usuário monitorado."
      : "O usuário monitorado não confirmou presença dentro do prazo estabelecido.";

    // Retorno do resultado
    return new Response(
      JSON.stringify({
        success: true,
        event_type: record.event_type,
        tokens_found: tokens.length,
        title,
        body,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
