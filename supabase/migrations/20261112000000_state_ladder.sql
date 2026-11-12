-- ========================================================
-- Vigi - Escada de estados no servidor
--
-- O app passou a seguir a escada do Guia de Design:
--
--   Vigiando -> Sua vez -> Última chamada -> Alerta
--
-- Entre o prazo do check-in e o aviso aos contatos há uma tolerância de
-- 15 minutos (ou do próprio intervalo, quando ele é menor que 15). Esta
-- migração faz o servidor esperar a mesma tolerância e avisar a família
-- também quando o pedido de ajuda é cancelado.
--
-- A regra de tempo espelha lib/features/checkin/domain/entities/
-- checkin_schedule.dart. Se uma mudar, a outra precisa mudar junto.
-- ========================================================

-- 1. Detecção de prazo expirado, com a tolerância da escada.
--
-- O aparelho avisa os contatos em prazo + tolerância. O servidor só age
-- 2 minutos depois disso, e só se o aparelho não agiu (desligado, sem
-- bateria, sem sinal, app encerrado). Antes desta migração ele agia em
-- prazo + 2 minutos, ou seja, ainda durante a chamada: a família recebia
-- um alerta enquanto a pessoa tinha tempo de responder.
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
      and ms.next_deadline
            + make_interval(mins => least(greatest(ms.interval_minutes, 1), 15))
            + interval '2 minutes' < now()
      and not exists (
          select 1 from public.checkin_events ce
          where ce.user_id = ms.user_id
            and ce.event_type = 'alert_triggered'
            and ce.created_at > ms.next_deadline
      );
end;
$$;

-- 2. O push também sai quando o pedido de ajuda é cancelado ("está tudo
-- bem"). A Edge Function decide o texto e só envia se a família chegou a
-- ser avisada do pedido.
drop trigger if exists on_alert_created on public.checkin_events;
create trigger on_alert_created
    after insert on public.checkin_events
    for each row
    when (new.event_type in ('panic', 'alert_triggered', 'alert_resolved'))
    execute function public.notify_on_alert();

-- 3. Mensagem do código de vínculo com o nome da marca como se escreve:
-- "Vigi". O restante da função é o mesmo de 20260925000200.
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
        raise exception 'Código Vigi não encontrado. Confira as letras e os números.';
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

grant execute on function public.request_family_link(text) to authenticated;
