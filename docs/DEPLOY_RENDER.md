# Publicando o VIGI Família no Render

O **VIGI Família** é o painel web (PWA) em que o familiar acompanha, sem invadir
a privacidade, quem o autorizou pelo app VIGI. Ele é um site estático gerado
pelo Flutter (`lib/main_family.dart`) e pode ser hospedado de graça no Render.

> O app do idoso continua sendo o **Android nativo** (APK): alarmes, SMS
> automático, widget e execução em segundo plano não funcionam num navegador.

## 1. Criar o site no Render (uma vez)

1. Entre em <https://dashboard.render.com> com sua conta do GitHub.
2. Clique em **New +** → **Blueprint**.
3. Escolha o repositório **geffinh0/vigi** e clique em **Connect**.
4. O Render lê o arquivo `render.yaml` e mostra o serviço **vigi-familia**
   (Static Site). Clique em **Apply** / **Deploy Blueprint**.
5. Aguarde o primeiro build (cerca de 5 a 10 minutos: o script baixa o Flutter
   e compila o painel). Ao final aparece o endereço, algo como
   `https://vigi-familia.onrender.com`.

Pronto: a cada `git push` na branch `main` o Render publica a versão nova
sozinho.

### Alternativa sem Blueprint (manual)

**New +** → **Static Site** → repositório `geffinh0/vigi`, com:

| Campo | Valor |
|---|---|
| Branch | `main` |
| Build Command | `bash scripts/render_build.sh` |
| Publish Directory | `build/web` |
| Environment Variable | `FLUTTER_VERSION` = `3.38.5` |

Depois, em **Redirects/Rewrites**, adicione: Source `/*` → Destination
`/index.html` → Action **Rewrite**.

## 2. Liberar o endereço no Supabase (uma vez)

Sem isto, o link do e-mail de confirmação de cadastro manda o usuário para o
endereço errado.

1. Supabase → projeto → **Authentication** → **URL Configuration**.
2. **Site URL**: o endereço do Render (ex.: `https://vigi-familia.onrender.com`).
3. Em **Redirect URLs**, adicione também `https://vigi-familia.onrender.com/**`.
4. Salve.

## 3. Apontar o app do idoso para o painel

O botão **"Enviar pelo WhatsApp"** (tela Família do app) inclui o link do
painel. Gere o APK informando o endereço:

```bash
flutter build apk --release --dart-define=FAMILY_WEB_URL=https://vigi-familia.onrender.com
```

## 4. Instalar como aplicativo (PWA)

- **Android (Chrome):** abra o endereço → menu ⋮ → **Instalar app**.
- **iPhone (Safari):** abra o endereço → Compartilhar → **Adicionar à Tela de
  Início**.
- **Computador (Chrome/Edge):** ícone de instalar na barra de endereço.

Com o painel aberto, emergências tocam um alarme e mostram notificação do
navegador. Com ele fechado, o familiar é avisado por **SMS** (enviado pelo
celular do idoso) e, se tiver o app Android, por **push**.

## Problemas comuns

| Sintoma | Solução |
|---|---|
| Build falha por falta de memória | Em **Settings** do site, tente novamente (**Manual Deploy → Clear build cache & deploy**). Se persistir, gere localmente com `flutter build web -t lib/main_family.dart --release` e publique a pasta `build/web` em um Static Site sem build command. |
| Página em branco após atualizar | Recarregue com Ctrl+Shift+R (o PWA guarda a versão anterior em cache). |
| "Código VIGI não encontrado" | Confira as 6 letras/números na tela **Família** do celular do idoso. |
| Painel não atualiza sozinho | Verifique se a migration `20260925000200_family_link_codes.sql` foi aplicada (`supabase db push`), pois ela ativa o Realtime. |
