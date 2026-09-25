// Edge Function: notify-emergency-contacts
// Envia push FCM (HTTP v1) aos familiares vinculados quando há pânico ou
// check-in expirado. ADR-001 (Canal 2: alerta remoto via FCM).
//
// Recebe apenas { event_id } — do gatilho do banco (inserção de 'panic' ou
// 'alert_triggered') ou do próprio app como reforço. O evento é carregado com a
// service role e "reivindicado" (notified_at), então cada alerta gera um único
// envio e o chamador não consegue forjar alertas.
// { healthcheck: true } valida a conta de serviço do Firebase sem enviar nada.
//
// Secret necessário: FIREBASE_SERVICE_ACCOUNT = JSON da conta de serviço do
// Firebase (Console Firebase > Configurações do projeto > Contas de serviço).

import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;

  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(`OAuth Google falhou: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

/// Aceita o JSON puro ou em base64 (recomendado no Windows, onde a linha de
/// comando remove as aspas internas do JSON ao salvar o secret).
function parseServiceAccount(raw: string): ServiceAccount {
  const text = raw.trim();
  try {
    return JSON.parse(text) as ServiceAccount;
  } catch (_) { /* tenta base64 */ }
  try {
    return JSON.parse(atob(text)) as ServiceAccount;
  } catch (_) { /* inválido */ }
  throw new Error(
    "FIREBASE_SERVICE_ACCOUNT inválido: salve o JSON da conta de serviço em base64",
  );
}

Deno.serve(async (req) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const payload = await req.json().catch(() => ({}));

    const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (payload.healthcheck === true) {
      if (!saRaw) return json({ ok: false, error: "FIREBASE_SERVICE_ACCOUNT ausente" }, 500);
      const sa = parseServiceAccount(saRaw);
      await getGoogleAccessToken(sa);
      return json({ ok: true, firebase_project: sa.project_id });
    }

    const eventId = payload.event_id ?? payload.record?.id;
    if (typeof eventId !== "string" || eventId.length === 0) {
      return json({ error: "Invalid payload" }, 400);
    }

    // Reivindica o evento: só alertas recentes e ainda não notificados.
    const cutoff = new Date(Date.now() - 30 * 60 * 1000).toISOString();
    const { data: event, error: claimError } = await supabaseAdmin
      .from("checkin_events")
      .update({ notified_at: new Date().toISOString() })
      .eq("id", eventId)
      .is("notified_at", null)
      .in("event_type", ["panic", "alert_triggered"])
      .gt("created_at", cutoff)
      .select("user_id, event_type, latitude, longitude")
      .maybeSingle();
    if (claimError) return json({ error: claimError.message }, 500);
    if (!event) {
      return json({ success: true, skipped: "já notificado, antigo ou inexistente" });
    }

    const releaseClaim = () =>
      supabaseAdmin
        .from("checkin_events")
        .update({ notified_at: null })
        .eq("id", eventId);

    const userId: string = event.user_id;
    const eventType: string = event.event_type;
    const latitude: number | null = event.latitude;
    const longitude: number | null = event.longitude;

    // 1. Familiares vinculados e aceitos
    const { data: viewers, error: linksError } = await supabaseAdmin
      .from("family_links")
      .select("viewer_user_id")
      .eq("monitored_user_id", userId)
      .eq("status", "accepted");
    if (linksError) return json({ error: linksError.message }, 500);

    const viewerIds = (viewers ?? []).map((v) => v.viewer_user_id);
    if (viewerIds.length === 0) {
      return json({ success: true, sent: 0, message: "Nenhum familiar vinculado" });
    }

    // 2. Tokens FCM dos familiares
    const { data: deviceTokens } = await supabaseAdmin
      .from("device_tokens")
      .select("id, fcm_token")
      .in("user_id", viewerIds);
    const tokens = deviceTokens ?? [];
    if (tokens.length === 0) {
      return json({ success: true, sent: 0, message: "Familiares sem token FCM" });
    }

    // 3. Mensagem
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("full_name")
      .eq("id", userId)
      .maybeSingle();
    const name = profile?.full_name?.trim() || "Seu familiar";
    const isPanic = eventType === "panic";
    const title = isPanic
      ? "🚨 VIGI — Botão de pânico acionado"
      : "⚠️ VIGI — Check-in não confirmado";
    const local = latitude != null && longitude != null
      ? ` Localização: https://maps.google.com/?q=${latitude},${longitude}`
      : "";
    const body = (isPanic
      ? `${name} acionou o botão de pânico.`
      : `${name} não confirmou que está bem no prazo combinado.`) + local;

    // 4. Envio FCM HTTP v1
    if (!saRaw) {
      await releaseClaim();
      return json({ error: "Secret FIREBASE_SERVICE_ACCOUNT não configurado" }, 500);
    }
    let accessToken: string;
    let sa: ServiceAccount;
    try {
      sa = parseServiceAccount(saRaw);
      accessToken = await getGoogleAccessToken(sa);
    } catch (e) {
      await releaseClaim();
      throw e;
    }

    let sent = 0;
    const errors: string[] = [];
    for (const t of tokens) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: t.fcm_token,
              notification: { title, body },
              data: {
                event_type: String(eventType),
                user_id: String(userId),
                latitude: latitude?.toString() ?? "",
                longitude: longitude?.toString() ?? "",
              },
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: "alerta_checkin",
                  sound: "default",
                },
              },
            },
          }),
        },
      );
      if (res.ok) {
        sent++;
      } else {
        const err = await res.text();
        errors.push(err);
        // Token inválido/desinstalado: remove para não tentar de novo
        if (res.status === 404 || err.includes("UNREGISTERED")) {
          await supabaseAdmin.from("device_tokens").delete().eq("id", t.id);
        }
      }
    }

    // Nenhum envio deu certo: libera o evento para uma nova tentativa (app)
    if (sent === 0) await releaseClaim();

    return json({ success: sent > 0, event_type: eventType, sent, total: tokens.length, errors });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Unknown error" },
      500,
    );
  }
});
