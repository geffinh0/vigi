# VIGI

Aplicativo de segurança assistiva para idosos e pessoas que vivem sozinhas,
baseado no princípio do **dead man's switch**: o silêncio é o gatilho. O VIGI
pede confirmações periódicas de bem-estar e, se não houver resposta, avisa
automaticamente os contatos de emergência com a localização. Há também um
botão de pânico.

## Componentes

| Parte | Tecnologia | Para quem |
|---|---|---|
| **App VIGI** (`lib/main.dart`) | Flutter / Android nativo | A pessoa acompanhada (idoso) |
| **VIGI Família** (`lib/main_family.dart`) | Flutter Web / PWA | O familiar que acompanha |
| **Backend** (`supabase/`) | Supabase: PostgreSQL, RLS, Realtime, pg_cron, Edge Functions | — |

### Como o alerta chega

1. **SMS automático** pelo celular do idoso (funciona sem internet).
2. **Push FCM** para familiares com o app, via Edge Function
   `notify-emergency-contacts`.
3. **Painel VIGI Família** em tempo real (Supabase Realtime / WebSockets).
4. **Dead man's switch no servidor** (`pg_cron`, a cada minuto): se o celular
   desligar ou ficar sem bateria, o servidor detecta o prazo vencido e avisa a
   família.

### Privacidade

A família vê apenas se a pessoa está bem, o último sinal e o próximo check-in.
A localização só é compartilhada em emergências, e o vínculo só existe se a
própria pessoa tocar em **Permitir** (código VIGI de 6 caracteres).

## Executando

```bash
flutter pub get
flutter run                                  # app do idoso (Android)
flutter run -d chrome -t lib/main_family.dart  # painel da família
flutter test                                 # testes
```

O app Android precisa do arquivo `android/app/google-services.json` (Firebase),
que não é versionado.

## Backend

```bash
supabase db push                                         # migrations
supabase functions deploy notify-emergency-contacts --use-api
```

Secret necessário na Edge Function: `FIREBASE_SERVICE_ACCOUNT` (JSON da conta de
serviço do Firebase, em base64).

## Publicação do painel

Veja [docs/DEPLOY_RENDER.md](docs/DEPLOY_RENDER.md).
