-- ========================================================
-- Guardião (v2) - Dead man's switch no servidor + push FCM
-- Garante o alerta aos familiares mesmo com o celular desligado, sem bateria
-- ou com o app fechado: o servidor detecta o prazo vencido sozinho.
-- ========================================================

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Evita push duplicado (o app e o servidor podem registrar o mesmo alerta)
alter table public.checkin_events
    add column if not exists notified_at timestamptz;

-- 1. Detecção de prazo expirado.
-- Tolerância de 2 min: o app toca o alarme no prazo e avisa os contatos após
-- 1 min sem resposta; o servidor só age se o app não o fez (ex.: desligado).
-- O alerta leva a última localização conhecida do usuário.
create or replace function public.check_expired_heartbeats()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.checkin_events (user_id, event_type, latitude, longitude)
    select ms.user_id, 'alert_triggered', loc.latitude, loc.longitude
    from public.monitoring_settings ms
    left join lateral (
        select ce.latitude, ce.longitude
        from public.checkin_events ce
        where ce.user_id = ms.user_id
          and ce.latitude is not null
        order by ce.created_at desc
        limit 1
    ) loc on true
    where ms.active = true
      and ms.next_deadline is not null
      and ms.next_deadline + interval '2 minutes' < now()
      and not exists (
          select 1 from public.checkin_events ce
          where ce.user_id = ms.user_id
            and ce.event_type = 'alert_triggered'
            and ce.created_at > ms.next_deadline
      );
end;
$$;

-- 2. Verificação a cada minuto (mesmo nome de job => atualiza o agendamento)
select cron.schedule(
    'check-heartbeats',
    '* * * * *',
    'select public.check_expired_heartbeats();'
);

-- 3. Gatilho de push: envia apenas o id do evento. A Edge Function carrega o
-- evento com a service role, então o chamador não consegue forjar alertas.
-- A chave usada é a anon/publishable (pública, já embarcada no app).
create or replace function public.notify_on_alert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    perform net.http_post(
        url := 'https://fojhaubpaglqbpubnpgo.supabase.co/functions/v1/notify-emergency-contacts',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvamhhdWJwYWdscWJwdWJucGdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4NDI1NzMsImV4cCI6MjEwMjQxODU3M30.7RSrUOgJHmxTd5AnU8mDgkmTOPu2aLzDtI8ikSMZ0nA'
        ),
        body := jsonb_build_object('event_id', new.id)
    );
    return new;
exception
    when others then
        -- Nunca impede o registro do evento se a chamada HTTP falhar
        return new;
end;
$$;

drop trigger if exists on_alert_created on public.checkin_events;
create trigger on_alert_created
    after insert on public.checkin_events
    for each row
    when (new.event_type in ('panic', 'alert_triggered'))
    execute function public.notify_on_alert();

-- 4. Diagnóstico (somente booleanos, sem dados de usuários) para validar a
-- infraestrutura do dead man's switch: select public.guardiao_health();
create or replace function public.guardiao_health()
returns jsonb
language sql
security definer
set search_path = public
as $$
    select jsonb_build_object(
        'pg_cron', exists (select 1 from pg_extension where extname = 'pg_cron'),
        'pg_net', exists (select 1 from pg_extension where extname = 'pg_net'),
        'heartbeat_job', exists (
            select 1 from cron.job
            where jobname = 'check-heartbeats' and active
        ),
        'heartbeat_schedule', (
            select schedule from cron.job where jobname = 'check-heartbeats' limit 1
        ),
        'alert_trigger', exists (
            select 1 from pg_trigger where tgname = 'on_alert_created'
        ),
        'dedupe_column', exists (
            select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name = 'checkin_events'
              and column_name = 'notified_at'
        )
    );
$$;

grant execute on function public.guardiao_health() to anon, authenticated;
