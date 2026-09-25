-- ========================================================
-- Guardião (v2) - Leitura do nome entre partes vinculadas
-- Sem esta policy o painel familiar não consegue exibir o nome do outro
-- usuário do vínculo (RLS de profiles só permitia ler o próprio perfil).
-- ========================================================

drop policy if exists "profiles_select_linked" on public.profiles;
create policy "profiles_select_linked" on public.profiles
    for select using (
        exists (
            select 1 from public.family_links fl
            where (fl.monitored_user_id = profiles.id and fl.viewer_user_id = auth.uid())
               or (fl.viewer_user_id = profiles.id and fl.monitored_user_id = auth.uid())
        )
    );
