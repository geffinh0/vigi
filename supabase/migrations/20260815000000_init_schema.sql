-- ========================================================
-- Guardião (v2) - Schema de Banco de Dados Versionado
-- ADR-001, ADR-002, ADR-003, Stage 3
-- ========================================================

-- Extensões necessárias
create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 1. PROFILES (1 linha por usuário, criada via trigger no cadastro)
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    phone text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
    for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
    for update using (auth.uid() = id);

-- Trigger de criação automática do profile no cadastro do Auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, full_name, phone)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', ''),
        new.raw_user_meta_data->>'phone'
    );
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- 2. EMERGENCY CONTACTS (N contatos por usuário)
create table if not exists public.emergency_contacts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    name text not null,
    phone text not null,
    relationship text,
    created_at timestamptz not null default now(),
    unique (user_id, phone)
);

alter table public.emergency_contacts enable row level security;

create policy "contacts_owner_all" on public.emergency_contacts
    for all using (auth.uid() = user_id);

-- 3. FAMILY LINKS (Vínculo de visualização familiar - privacidade protegida)
create table if not exists public.family_links (
    id uuid primary key default gen_random_uuid(),
    monitored_user_id uuid not null references public.profiles(id) on delete cascade,
    viewer_user_id uuid not null references public.profiles(id) on delete cascade,
    status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
    created_at timestamptz not null default now(),
    unique (monitored_user_id, viewer_user_id)
);

alter table public.family_links enable row level security;

create policy "family_links_involved_parties" on public.family_links
    for all using (auth.uid() in (monitored_user_id, viewer_user_id));

-- 4. MONITORING SETTINGS (Dead Man's Switch - 1 por usuário)
create table if not exists public.monitoring_settings (
    user_id uuid primary key references public.profiles(id) on delete cascade,
    interval_minutes int not null default 60,
    active boolean not null default false,
    next_deadline timestamptz,
    last_ping timestamptz,
    updated_at timestamptz not null default now()
);

alter table public.monitoring_settings enable row level security;

create policy "monitoring_owner_all" on public.monitoring_settings
    for all using (auth.uid() = user_id);

create policy "monitoring_family_read" on public.monitoring_settings
    for select using (
        exists (
            select 1 from public.family_links fl
            where fl.monitored_user_id = monitoring_settings.user_id
              and fl.viewer_user_id = auth.uid()
              and fl.status = 'accepted'
        )
    );

-- 5. CHECKIN EVENTS (Histórico de eventos, rotina, pânico e alertas)
create table if not exists public.checkin_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    event_type text not null check (event_type in ('checkin', 'routine_start', 'panic', 'alert_triggered', 'alert_resolved')),
    latitude double precision,
    longitude double precision,
    created_at timestamptz not null default now()
);

alter table public.checkin_events enable row level security;

create policy "events_owner_all" on public.checkin_events
    for all using (auth.uid() = user_id);

create policy "events_family_read" on public.checkin_events
    for select using (
        exists (
            select 1 from public.family_links fl
            where fl.monitored_user_id = checkin_events.user_id
              and fl.viewer_user_id = auth.uid()
              and fl.status = 'accepted'
        )
    );

-- 6. DEVICE TOKENS (FCM Push Tokens para Alertas Remotos - Canal 2)
create table if not exists public.device_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    fcm_token text not null,
    platform text not null,
    updated_at timestamptz not null default now(),
    unique (user_id, fcm_token)
);

alter table public.device_tokens enable row level security;

create policy "tokens_owner_all" on public.device_tokens
    for all using (auth.uid() = user_id);

-- 7. AUDITORIA DO DEAD MAN'S SWITCH (Função de auditoria de prazo expirado no servidor)
create or replace function public.check_expired_heartbeats()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.checkin_events (user_id, event_type)
    select user_id, 'alert_triggered'
    from public.monitoring_settings
    where active = true
      and next_deadline < now()
      and not exists (
          select 1 from public.checkin_events ce
          where ce.user_id = monitoring_settings.user_id
            and ce.event_type = 'alert_triggered'
            and ce.created_at > monitoring_settings.next_deadline
      );
end;
$$;

-- Agendamento de execução periódica (a cada 15 min via pg_cron)
-- O bloco é executado de forma idempotente
do $$
begin
    if exists (select 1 from pg_extension where extname = 'pg_cron') then
        perform cron.schedule(
            'check-heartbeats',
            '*/15 * * * *',
            'select public.check_expired_heartbeats();'
        );
    end if;
exception
    when others then
        null;
end;
$$;

-- 8. GATILHO PARA NOTIFICAÇÕES REMOTAS (Edge Function FCM - Stage 8)
create or replace function public.notify_on_alert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    supabase_url text := current_setting('app.settings.supabase_url', true);
    service_role_key text := current_setting('app.settings.service_role_key', true);
begin
    if supabase_url is not null and service_role_key is not null then
        perform net.http_post(
            url := supabase_url || '/functions/v1/notify-emergency-contacts',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || service_role_key
            ),
            body := jsonb_build_object('record', row_to_json(new))
        );
    end if;
    return new;
exception
    when others then
        -- Não impede inserção do evento se a chamada HTTP falhar
        return new;
end;
$$;

drop trigger if exists on_alert_created on public.checkin_events;
create trigger on_alert_created
    after insert on public.checkin_events
    for each row
    when (new.event_type in ('panic', 'alert_triggered'))
    execute function public.notify_on_alert();
