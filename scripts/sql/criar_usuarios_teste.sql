-- ============================================================
-- VIGI - Cria duas contas de teste já confirmadas (idoso e família)
--
-- Uso: Supabase > SQL Editor > cole este arquivo, preencha os campos
-- marcados com ✏️ e clique em Run. Não versione senhas reais.
-- ============================================================

-- Função temporária (existe apenas nesta execução)
create or replace function pg_temp.criar_usuario(
  p_email text, p_senha text, p_nome text, p_fone text
) returns uuid language plpgsql as $$
declare
  v_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    lower(p_email), extensions.crypt(p_senha, extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', p_nome, 'phone', p_fone),
    now(), now(), '', '', '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_id, v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', lower(p_email), 'email_verified', true),
    'email', now(), now(), now()
  );
  return v_id;
end $$;

do $$
declare
  v_idoso uuid;
  v_familia uuid;
begin
  v_idoso := pg_temp.criar_usuario(
    'SEUEMAIL+idoso@gmail.com',    -- ✏️ e-mail do idoso
    'SENHA_IDOSO',                 -- ✏️ senha (mínimo 6 caracteres)
    'Dona Maria', null);

  v_familia := pg_temp.criar_usuario(
    'SEUEMAIL+familia@gmail.com',  -- ✏️ e-mail do familiar
    'SENHA_FAMILIA',               -- ✏️ senha (mínimo 6 caracteres)
    'Carla (filha)', null);

  -- Contato de emergência do idoso (quem recebe o SMS)
  insert into public.emergency_contacts (user_id, name, phone, relationship)
  values (v_idoso, 'Carla (filha)',
    '+5511999999999',              -- ✏️ telefone com código do país
    'Filha');

  -- OPCIONAL: descomente para já deixar o vínculo autorizado
  -- (pula o teste do código VIGI)
  -- insert into public.family_links (monitored_user_id, viewer_user_id, status)
  -- values (v_idoso, v_familia, 'accepted');
end $$;

-- Conferência
select u.email, p.full_name,
       (select string_agg(c.phone, ', ') from public.emergency_contacts c
        where c.user_id = u.id) as contato_sms
from auth.users u
join public.profiles p on p.id = u.id;
