# Como testar o VIGI

Roteiro para testar o sistema completo com **um celular Android** (papel do
idoso) e **um computador ou outro celular** (papel da família).

## O que você precisa

- Celular **Android** com chip (para o SMS) e internet.
- O arquivo **`app-release.apk`** do VIGI.
- Um navegador (Chrome, Edge ou Safari) para o **VIGI Família**:
  - endereço publicado no Render (peça ao autor), ou
  - rodando localmente: `flutter run -d chrome -t lib/main_family.dart`.
- Dois e-mails. Dica com Gmail: `seuemail+idoso@gmail.com` e
  `seuemail+familia@gmail.com` chegam na mesma caixa, mas são contas diferentes.

## 1. Instalar o app do idoso

1. Envie o `app-release.apk` para o celular e toque nele.
2. Se aparecer um aviso, permita **"instalar apps desconhecidos"**.
3. Abra o app **VIGI** (ícone de escudo com um "check" laranja) e **aceite todas
   as permissões**: notificações, SMS e localização.
4. Toque em **Criar conta** e cadastre-se com o e-mail **+idoso**.
   - Se aparecer "Cadastro criado! Abra o link enviado…", confirme pelo e-mail e
     depois faça login.

## 2. Cadastrar um contato de emergência

1. Na tela inicial, toque no ícone de **contatos** (agenda).
2. Adicione um contato com um número que você consiga ver — pode ser o
   **próprio número do celular**, para ver o SMS chegar nele mesmo.
   - Aceita número do Brasil com DDD ou internacional com `+` (ex.: `+351…`).

> O monitoramento só inicia se houver ao menos um contato cadastrado.

## 3. Vincular a família (código VIGI)

1. **No celular:** toque no ícone de **pessoas** (Família). Aparece
   **"Seu código VIGI"**, por exemplo `K7P-2QX`.
2. **No VIGI Família (navegador):** crie a conta com o e-mail **+familia**, toque
   em **"Acompanhar uma pessoa"** e digite o código.
3. **No celular:** aparece *"… quer acompanhar você"*. Toque em **Permitir**.
4. O painel passa a mostrar a pessoa acompanhada.

## 4. Roteiro de testes

| # | Ação (no celular) | Resultado esperado |
|---|---|---|
| 1 | Toque em **Iniciar Rotina padrão** | Contagem regressiva no app; painel mostra **"Está tudo bem"** e o próximo check-in |
| 2 | Toque em **Estou Bem** | Contagem reinicia; painel atualiza o "Último sinal" |
| 3 | Segure o **botão de pânico** por 3 s | SMS com link do mapa chega ao contato; tela mostra "SMS enviado para 1 de 1"; painel fica **vermelho** com alarme e botão **"Ver localização do alerta"** |
| 4 | Toque em **Estou Seguro — Cancelar Alerta** | Painel volta ao normal |
| 5 | Em **Configurações** (engrenagem), coloque **1 minuto** e inicie; **não responda** | Após 1 min: alarme toca no celular e o painel mostra **"Check-in atrasado"**. Após mais 1 min sem resposta: SMS enviado e o painel mostra **"Não respondeu ao check-in"** |
| 6 | Repita o teste 5, mas toque em **ESTOU BEM** antes de 1 min de alarme | Nenhum SMS é enviado |
| 7 | Inicie com 1 minuto e **desligue o celular** (ou ative o modo avião) | Em até ~3 min o **servidor** detecta a falta de resposta e o painel mostra a emergência (sem SMS, pois o celular está desligado) |
| 8 | Tela **Família** → **Remover** a pessoa que acompanha | Ela some do painel da família |
| 9 | Adicione o **widget** VIGI na tela inicial do Android e toque em "Estou bem" | O app abre e confirma o check-in |

## 5. Problemas comuns

| Sintoma | O que fazer |
|---|---|
| App pede **UUID do familiar** | É uma versão antiga. Desinstale e instale o APK mais recente. |
| SMS não chega | Verifique sinal da operadora e saldo; SMS internacional pode ser bloqueado pela operadora. Confira se a permissão de SMS foi aceita. |
| "Cadastre ao menos um contato…" ao iniciar | Cadastre um contato de emergência (passo 2). |
| "Código VIGI não encontrado" | Confira as 6 letras/números na tela Família do celular. |
| Painel não atualiza | Recarregue a página com **Ctrl + Shift + R**. |
| Alarme não toca com o app fechado | Em alguns aparelhos é preciso liberar o VIGI da **economia de bateria** (Configurações → Bateria → VIGI → Sem restrições). |

## 6. Para quem administra o Supabase

Para criar contas de teste já confirmadas (sem e-mail), use o script
[`scripts/sql/criar_usuarios_teste.sql`](../scripts/sql/criar_usuarios_teste.sql)
no **SQL Editor** do Supabase, preenchendo os campos marcados com ✏️.

Para verificar a infraestrutura do dead man's switch:

```sql
select public.guardiao_health();
```
