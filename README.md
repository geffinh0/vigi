# Vigi

Aplicativo de **segurança assistiva** para idosos e pessoas que vivem sozinhas,
baseado no princípio do **dead man's switch**: o silêncio é o gatilho. O Vigi pede
confirmações periódicas de bem-estar ("Estou bem") e, se não houver resposta,
avisa automaticamente os contatos de emergência com a localização. Há também um
botão de pânico e um painel web para a família acompanhar sem invadir a
privacidade.

> Projeto de TCC. Flutter + Supabase + Firebase Cloud Messaging.

---

## Sumário

- [Visão geral](#visão-geral)
- [A escada de estados](#a-escada-de-estados)
- [Identidade visual](#identidade-visual)
- [Como testar (sem compilar nada)](#como-testar-sem-compilar-nada)
- [Rodando a partir do código](#rodando-a-partir-do-código)
- [Configuração](#configuração)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Backend (Supabase)](#backend-supabase)
- [Testes automatizados](#testes-automatizados)
- [Limitações conhecidas](#limitações-conhecidas)
- [Documentação complementar](#documentação-complementar)

---

## Visão geral

| Parte | Entrada | Tecnologia | Usuário |
|---|---|---|---|
| **App Vigi** | `lib/main.dart` | Flutter, Android nativo | Pessoa acompanhada (idoso) |
| **Vigi Família** | `lib/main_family.dart` | Flutter Web / PWA | Familiar ou cuidador |
| **Backend** | `supabase/` | PostgreSQL, RLS, Realtime, pg_cron, Edge Functions | — |

```mermaid
flowchart LR
    subgraph Idoso["📱 App Vigi (Android)"]
        T[Vigiando] -->|prazo vence| A[Sua vez: chamada]
        A -->|sem resposta| U[Última chamada: alarme]
        U -->|fim da tolerância| SMS[SMS nativo aos contatos]
        P[Pedir ajuda: segurar 3 s] --> SMS
    end
    subgraph Supabase
        DB[(PostgreSQL + RLS)]
        CRON[pg_cron a cada minuto]
        EF[Edge Function<br/>notify-emergency-contacts]
        RT[Realtime / WebSockets]
    end
    Idoso -->|check-ins e alertas| DB
    CRON -->|prazo + tolerância + 2 min<br/>celular sem resposta| DB
    DB -->|gatilho em alerta| EF
    EF -->|push FCM| FAM1[📱 Familiar com app]
    DB --> RT --> FAM2[💻 Vigi Família PWA]
```

**Canais de alerta (redundantes):**

1. **SMS automático** pelo chip do idoso — funciona sem internet.
2. **Push FCM** para familiares com o app instalado.
3. **Painel Vigi Família** em tempo real, com alarme sonoro e notificação do navegador.
4. **Dead man's switch no servidor** — se o celular desligar ou ficar sem bateria,
   o próprio banco detecta o prazo vencido e dispara o alerta.

**Privacidade:** a família vê apenas se a pessoa está bem, o último sinal e o
próximo check-in. A localização só é compartilhada em emergências, e o vínculo
só existe se a pessoa acompanhada tocar em **Permitir**.

---

## A escada de estados

O Vigi nunca vai direto do silêncio ao alerta. Cada degrau tem cor, coruja,
som e texto próprios, e a pessoa sempre sabe o que acontece a seguir, quando e
para quem.

| Estado | Quando | O que a pessoa vê e ouve |
|---|---|---|
| **Descansando** | Vigília pausada | Coruja de olhos fechados, cinza. O Vigi não finge proteger. |
| **Vigiando** | Entre check-ins | Anel de tempo Petróleo, horário do próximo check-in. |
| **Sua vez** | No prazo | Tela Âmbar, "Está tudo bem, Lúcia?", botão "Estou bem" de 96 dp, som suave. |
| **Última chamada** | Minutos finais | Alarme, vibração longa e tela cheia mesmo com o celular bloqueado. |
| **Alerta** | Fim da tolerância | Tela Sinal: quem foi avisado, a que horas, e como cancelar. |
| **Aliviado** | Logo após confirmar | Coruja pisca, "Que bom", próximo horário. |
| **Noturno** | Modo Sono | Tema escuro, sem branco puro. |

Tempos (em [`checkin_schedule.dart`](lib/features/checkin/domain/entities/checkin_schedule.dart)):

- **Tolerância** entre o prazo e o aviso aos contatos: 15 minutos, ou o
  próprio intervalo quando ele é menor (um modo de 5 min tolera 5 min).
- **Última chamada:** o terço final da tolerância, até 5 minutos.
- **"Preciso de mais 10 minutos":** uma vez por ciclo.
- **Servidor:** age 2 minutos depois do fim da tolerância, e só se o aparelho
  não agiu. A mesma regra está na migration `20261112000000_state_ladder`.

Exemplo no modo Rotina (1 h): 15:00 chamada → 15:10 última chamada → 15:15
contatos avisados → 15:17 o servidor avisa a família se o celular não avisou.

---

## Identidade visual

O app segue o **Guia de Design do Vigi 1.0**. Tudo sai de um lugar só:

| O quê | Onde |
|---|---|
| Cores (Linho, Petróleo, Âmbar, Sinal) | [`lib/core/theme/app_colors.dart`](lib/core/theme/app_colors.dart) |
| Tipografia (Nunito + Atkinson Hyperlegible, mínimo 14) | [`lib/core/theme/app_typography.dart`](lib/core/theme/app_typography.dart) |
| Espaços, raios, áreas de toque, tempos de animação | [`lib/core/theme/vigi_tokens.dart`](lib/core/theme/vigi_tokens.dart) |
| Estados da coruja e de cada degrau | [`lib/core/theme/vigi_state.dart`](lib/core/theme/vigi_state.dart) |
| Coruja (mascote e símbolo) | [`lib/core/widgets/vigi_mascot.dart`](lib/core/widgets/vigi_mascot.dart) |
| Textos da escada (voz do Vigi) | [`lib/core/services/checkin_messages.dart`](lib/core/services/checkin_messages.dart) |

Regras que o código e os testes cobram: **uma cor, um significado** (Âmbar é
"sua vez"; vermelho só em pedido de ajuda), áreas de toque de pelo menos 56 dp,
nada em caixa alta, contraste AA e telas que funcionam com a fonte do sistema
em 200%.

Ícones, tela de abertura, ícone de notificação e as corujas do widget são
gerados da mesma geometria, e os sons são sintetizados:

```bash
python3 scripts/make_icons.py    # ícones de todas as plataformas e vetores do Android
python3 scripts/make_sounds.py   # chamada, última chamada e alerta
```

As fontes ficam em `assets/fonts/` (licença OFL incluída): o app não baixa
nada da internet para desenhar a interface.

---

## Como testar (sem compilar nada)

Guia passo a passo com roteiro de testes: **[docs/TESTE.md](docs/TESTE.md)**.

Resumo:

1. Instale o **APK** do Vigi em um celular Android (peça o arquivo ao autor ou
   gere com `flutter build apk --release`).
2. Abra o **Vigi Família** no navegador (endereço publicado no Render ou
   `flutter run -d chrome -t lib/main_family.dart`).
3. Crie uma conta em cada um, vincule pelo **código Vigi** e teste o pânico e o
   check-in.

---

## Rodando a partir do código

### Pré-requisitos

- **Flutter 3.38.5** (Dart 3.10) — `flutter --version`
- **Android SDK** (Android Studio) e um celular com depuração USB ou emulador
- Chrome, para o painel web

### Passos

```bash
git clone https://github.com/geffinh0/vigi.git
cd vigi
flutter pub get

flutter run                                     # app do idoso (Android)
flutter run -d chrome -t lib/main_family.dart   # painel da família (web)
```

Gerar os pacotes finais:

```bash
flutter build apk --release                             # build/app/outputs/flutter-apk/app-release.apk
flutter build web -t lib/main_family.dart --release     # build/web
```

> O SMS automático, o alarme em segundo plano e o widget só funcionam em
> **celular Android real** (no emulador o SMS não é entregue).

---

## Configuração

**Não é necessário nenhum arquivo `.env`.** O app não lê `.env`: o endereço do
Supabase e a chave pública (*anon/publishable key*) ficam em
[`lib/app/config/app_config.dart`](lib/app/config/app_config.dart). Essa chave é
pública por natureza (vai dentro do APK) — a segurança dos dados é garantida pelo
**Row Level Security** no banco.

Valores opcionais via `--dart-define`:

| Variável | Uso | Padrão |
|---|---|---|
| `SUPABASE_URL` | Projeto Supabase | projeto do TCC |
| `SUPABASE_PUBLISHABLE_KEY` | Chave pública do projeto | chave do TCC |
| `FAMILY_WEB_URL` | Link do painel enviado no convite por WhatsApp | vazio |

Exemplo: `flutter build apk --release --dart-define=FAMILY_WEB_URL=https://vigi-familia.onrender.com`

### Firebase (push) — opcional

O arquivo `android/app/google-services.json` **não é versionado**. Sem ele o app
compila e funciona normalmente; apenas o **push para familiares fica desativado**
(SMS e painel web continuam funcionando). Para ativar o push, coloque o arquivo do
projeto Firebase nesse caminho.

---

## Estrutura do projeto

O código segue **Clean Architecture** por funcionalidade, com **BLoC** na
apresentação. Detalhes em **[docs/ARQUITETURA.md](docs/ARQUITETURA.md)**.

```
lib/
├── main.dart                 # entrada do app do idoso
├── main_family.dart          # entrada do painel web da família
├── bootstrap.dart            # inicialização (Supabase, DI, notificações, push)
├── app/                      # raiz do app, abas (Início, Modos, Pessoas), permissões
├── family_web/               # app web da família (roteador e composição)
├── injection/                # injeção de dependências (get_it)
├── core/
│   ├── services/             # alarme, notificações, SMS de emergência, push FCM, widget,
│   │                         # saúde do sistema (permissões, bateria, internet)
│   ├── router/               # rotas (go_router)
│   ├── theme/ widgets/       # tokens do Guia de Design, coruja e componentes
│   └── errors/ utils/        # Failure, logger, relógio, localização
└── features/
    ├── auth/                 # login e cadastro
    ├── checkin/              # dead man's switch (escada de estados, modos, prazos)
    ├── contacts/             # contatos de emergência
    ├── panic/                # botão de pânico
    └── family/               # vínculo com consentimento + painel da família
        (cada feature: data/ → domain/ → presentation/)

android/app/src/main/kotlin/…
├── MainActivity.kt           # canais nativos: SMS (SmsManager) e ajustes do sistema
└── GuardiaoWidgetProvider.kt # widget 2x2: coruja, próximo check-in e "Estou bem"

scripts/
├── make_icons.py             # gera ícones, abertura e vetores do widget
└── make_sounds.py            # sintetiza os sons do Vigi

supabase/
├── migrations/               # esquema, RLS, cron, gatilhos, RPCs
└── functions/notify-emergency-contacts/   # push FCM HTTP v1
```

> O nome interno do pacote continua `guardiao` (e o `applicationId`
> `com.guardiao.guardiao`) porque o projeto Firebase está registrado com ele.
> O nome exibido ao usuário é **Vigi**.

---

## Backend (Supabase)

Projeto já configurado. Para recriar em outro projeto:

```bash
supabase link --project-ref <SEU_PROJECT_REF>
supabase db push                                               # aplica as migrations
supabase functions deploy notify-emergency-contacts --use-api  # publica a Edge Function
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(base64 -w0 conta-de-servico.json)"
```

| Migration | O que faz |
|---|---|
| `20260815000000_init_schema` | Tabelas, RLS e gatilho de criação de perfil |
| `20260816000000_add_monitoring_modes` | Modos Rotina/Banho/Sono e personalizados |
| `20260925000000_family_profiles_read` | Familiares vinculados leem o nome um do outro |
| `20260925000100_server_dead_mans_switch` | pg_cron a cada minuto + gatilho de push + `guardiao_health()` |
| `20260925000200_family_link_codes` | Código Vigi, vínculo com consentimento, RLS e Realtime |
| `20261112000000_state_ladder` | Tolerância da escada de estados no servidor e push de "está tudo bem" |

> **Ao atualizar para a versão 2.1**, aplique a migration nova e publique de
> novo a Edge Function (`supabase db push` e `supabase functions deploy
> notify-emergency-contacts --use-api`). Sem isso o servidor continua agindo
> 2 minutos depois do prazo, ou seja, ainda durante a chamada, e a família
> recebe um alerta enquanto a pessoa tem tempo de responder.

Diagnóstico da infraestrutura (SQL Editor): `select public.guardiao_health();`

⚠️ Nunca versione a conta de serviço do Firebase nem a *service role key* do Supabase.

---

## Testes automatizados

```bash
flutter analyze   # análise estática (very_good_analysis)
flutter test      # testes unitários, de BLoC, de widget e de imagem (goldens)
```

Cobrem, entre outros: a escada de estados inteira (chamada, última chamada,
"mais 10 minutos", aviso aos contatos e cancelamento), check-in sem internet,
envio de SMS (normalização de telefones BR/internacionais), pedido de ajuda com
servidor fora do ar, regra de status do painel da família e casos de uso de
vínculo.

Os critérios do Guia de Design também são testados: contraste AA das
combinações de cor, tamanhos mínimos de toque, textos sem caixa alta, leitor de
tela e todas as telas com a fonte em 200%.

Os **goldens** (imagens de referência em `test/**/goldens/`) só são comparados
no Linux, que é onde o CI roda; em outros sistemas a renderização de fontes
difere e eles são ignorados. Para atualizar depois de mudar o visual:

```bash
flutter test --update-goldens
```

---

## Limitações conhecidas

- Para o alarme tocar na hora com o celular em repouso, o Android precisa das
  permissões de **alarmes**, **tela cheia** e de o Vigi ficar **fora da
  economia de bateria**. A tela "Permissões" explica e pede cada uma; o que
  faltar aparece no topo da tela inicial.
- **SMS** depende de sinal da operadora e pode ser cobrado (internacional
  costuma ser). O app confirma que a mensagem foi entregue à operadora, não o
  recebimento.
- Com o **celular desligado**, só o servidor consegue avisar (push e painel); o
  SMS precisa do aparelho ligado.
- O app do idoso é **Android**; navegadores não permitem alarmes em segundo
  plano nem SMS automático, por isso ele não é PWA.
- **Push web** (painel fechado) não está implementado: com o painel aberto há
  alarme e notificação do navegador; fechado, o familiar recebe o SMS.

---

## Documentação complementar

- [docs/TESTE.md](docs/TESTE.md) — como testar, passo a passo
- [docs/ARQUITETURA.md](docs/ARQUITETURA.md) — camadas, fluxos e banco de dados
- [docs/DEPLOY_RENDER.md](docs/DEPLOY_RENDER.md) — publicar o painel no Render
