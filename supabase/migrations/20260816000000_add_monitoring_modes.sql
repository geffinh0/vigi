-- ========================================================
-- Guardião (v2) - Modos de Monitoramento e Correção de Default
-- Ticket 01 - Migration: add_monitoring_modes
-- ========================================================

-- 1. Criação da tabela de modos de monitoramento
create table if not exists public.monitoring_modes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade, -- null = modo padrão do sistema
  name text not null,
  icon_key text,
  default_interval_minutes int not null check (default_interval_minutes > 0),
  is_system_default boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.monitoring_modes enable row level security;

drop policy if exists "modes_read_system_or_own" on public.monitoring_modes;
create policy "modes_read_system_or_own" on public.monitoring_modes
  for select using (user_id is null or user_id = auth.uid());

drop policy if exists "modes_manage_own" on public.monitoring_modes;
create policy "modes_manage_own" on public.monitoring_modes
  for all using (user_id = auth.uid());

-- Catálogo inicial de modos padrão do sistema (idempotente)
insert into public.monitoring_modes (name, icon_key, default_interval_minutes, is_system_default)
select 'Rotina padrão', 'routine', 60, true
where not exists (select 1 from public.monitoring_modes where name = 'Rotina padrão' and is_system_default = true);

insert into public.monitoring_modes (name, icon_key, default_interval_minutes, is_system_default)
select 'Banho', 'shower', 20, true
where not exists (select 1 from public.monitoring_modes where name = 'Banho' and is_system_default = true);

insert into public.monitoring_modes (name, icon_key, default_interval_minutes, is_system_default)
select 'Sono', 'sleep', 480, true
where not exists (select 1 from public.monitoring_modes where name = 'Sono' and is_system_default = true);

-- 2. Adiciona referência do modo ativo em monitoring_settings
alter table public.monitoring_settings
  add column if not exists active_mode_id uuid references public.monitoring_modes(id);

-- 3. Atualização segura de handle_new_user() para criar monitoring_settings no cadastro
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_default_mode_id uuid;
  v_default_interval int;
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone'
  );

  select id, default_interval_minutes into v_default_mode_id, v_default_interval
  from public.monitoring_modes
  where is_system_default and name = 'Rotina padrão'
  limit 1;

  insert into public.monitoring_settings (user_id, interval_minutes, active, active_mode_id)
  values (new.id, coalesce(v_default_interval, 60), false, v_default_mode_id);

  return new;
end;
$$;

-- 4. Backfill para perfis já cadastrados que não possuem linha em monitoring_settings
insert into public.monitoring_settings (user_id, interval_minutes, active, active_mode_id)
select
  p.id,
  coalesce((select default_interval_minutes from public.monitoring_modes where is_system_default and name = 'Rotina padrão' limit 1), 60),
  false,
  (select id from public.monitoring_modes where is_system_default and name = 'Rotina padrão' limit 1)
from public.profiles p
where not exists (
  select 1 from public.monitoring_settings ms where ms.user_id = p.id
);
