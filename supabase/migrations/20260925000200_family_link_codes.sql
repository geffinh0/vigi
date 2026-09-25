-- ========================================================
-- VIGI - Vínculo familiar por código curto e com consentimento
--
-- Fluxo: o idoso compartilha seu código VIGI (ex.: K7P2QX); o familiar o
-- digita no VIGI Família; o vínculo fica pendente até o IDOSO autorizar.
-- Antes, o vínculo exigia trocar UUIDs e o RLS permitia que o próprio
-- familiar marcasse o vínculo como "accepted" (sem consentimento).
-- ========================================================

-- 1. Código curto por perfil (sem caracteres ambíguos: 0/O, 1/I/L)
alter table public.profiles add column if not exists link_code text unique;

create or replace function public.generate_link_code()
returns text
language plpgsql
as $$
declare
    alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    code text;
begin
    loop
        code := '';
        for i in 1..6 loop
            code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
        end loop;
        exit when not exists (select 1 from public.profiles where link_code = code);
    end loop;
    return code;
end;
$$;

-- 2. Código do usuário logado (gerado na primeira consulta)
create or replace function public.get_my_link_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_code text;
begin
    if auth.uid() is null then
        raise exception 'Usuário não autenticado';
    end if;

    select link_code into v_code from public.profiles where id = auth.uid();
    if v_code is null then
        v_code := public.generate_link_code();
        update public.profiles set link_code = v_code where id = auth.uid();
    end if;
    return v_code;
end;
$$;

-- 3. Familiar pede para acompanhar alguém pelo código
create or replace function public.request_family_link(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_target public.profiles%rowtype;
    v_link public.family_links%rowtype;
    v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
begin
    if auth.uid() is null then
        raise exception 'Usuário não autenticado';
    end if;

    select * into v_target from public.profiles where link_code = v_code;
    if not found then
        raise exception 'Código VIGI não encontrado. Confira as letras e números.';
    end if;
    if v_target.id = auth.uid() then
        raise exception 'Este é o seu próprio código.';
    end if;

    insert into public.family_links (monitored_user_id, viewer_user_id, status)
    values (v_target.id, auth.uid(), 'pending')
    on conflict (monitored_user_id, viewer_user_id) do update
        set status = case
            when public.family_links.status = 'rejected' then 'pending'
            else public.family_links.status
        end
    returning * into v_link;

    return jsonb_build_object(
        'link_id', v_link.id,
        'status', v_link.status,
        'monitored_name', v_target.full_name
    );
end;
$$;

-- 4. Somente a pessoa acompanhada autoriza ou recusa
create or replace function public.respond_family_link(p_link_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.family_links
    set status = case when p_accept then 'accepted' else 'rejected' end
    where id = p_link_id
      and monitored_user_id = auth.uid();

    if not found then
        raise exception 'Pedido não encontrado.';
    end if;
end;
$$;

grant execute on function public.get_my_link_code() to authenticated;
grant execute on function public.request_family_link(text) to authenticated;
grant execute on function public.respond_family_link(uuid, boolean) to authenticated;
revoke execute on function public.generate_link_code() from public, anon, authenticated;

-- 5. RLS: clientes só leem e removem vínculos; criar/autorizar só via funções
drop policy if exists "family_links_involved_parties" on public.family_links;

drop policy if exists "family_links_select_involved" on public.family_links;
create policy "family_links_select_involved" on public.family_links
    for select using (auth.uid() in (monitored_user_id, viewer_user_id));

drop policy if exists "family_links_delete_involved" on public.family_links;
create policy "family_links_delete_involved" on public.family_links
    for delete using (auth.uid() in (monitored_user_id, viewer_user_id));

-- 6. Realtime (WebSockets) para o painel da família atualizar sozinho
do $$
declare
    t text;
begin
    if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
        return;
    end if;
    foreach t in array array['checkin_events', 'monitoring_settings', 'family_links'] loop
        if not exists (
            select 1 from pg_publication_tables
            where pubname = 'supabase_realtime'
              and schemaname = 'public'
              and tablename = t
        ) then
            execute format('alter publication supabase_realtime add table public.%I', t);
        end if;
    end loop;
end;
$$;
