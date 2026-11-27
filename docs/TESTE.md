# Como testar o Vigi

Roteiro para testar o sistema completo com **um celular Android** (papel do
idoso) e **um computador ou outro celular** (papel da família).

## O que você precisa

- Celular **Android** com chip (para o SMS) e internet.
- O arquivo **`app-release.apk`** do Vigi.
- Um navegador (Chrome, Edge ou Safari) para o **Vigi Família**:
  - endereço publicado no Render (peça ao autor), ou
  - rodando localmente: `flutter run -d chrome -t lib/main_family.dart`.
- Dois e-mails. Dica com Gmail: `seuemail+idoso@gmail.com` e
  `seuemail+familia@gmail.com` chegam na mesma caixa, mas são contas diferentes.

## 1. Instalar o app do idoso

1. Envie o `app-release.apk` para o celular e toque nele.
2. Se aparecer um aviso, permita **"instalar apps desconhecidos"**.
3. Abra o app **Vigi** (ícone Petróleo com a coruja de olhos Âmbar).
4. Toque em **Criar conta** e cadastre-se com o e-mail **+idoso**.
   - Se aparecer "Cadastro criado! Abra o link enviado…", confirme pelo e-mail e
     depois faça login.
5. Na primeira vez aparece a tela **"Para o Vigi cuidar de você"**. Ela explica
   cada permissão antes de o Android perguntar. Toque em **Permitir** em cada
   card (notificações, SMS, localização, alarmes, tela cheia e bateria) e
   depois em **Continuar**.
   - Nada é pedido sem você tocar. O que ficar faltando aparece em uma faixa
     Âmbar no topo da tela inicial, com o botão que resolve.
   - Para voltar a essa tela: aba **Pessoas** → **Ver permissões**.

## 2. Cadastrar uma pessoa de vigília

1. Toque na aba **Pessoas** e em **Adicionar pessoa**.
2. Use um número que você consiga ver — pode ser o **próprio número do
   celular**, para ver o SMS chegar nele mesmo.
   - Aceita número do Brasil com DDD ou internacional com `+` (ex.: `+351…`).

> O Vigi só começa a vigiar depois que houver ao menos uma pessoa cadastrada.

## 3. Vincular a família (código de convite)

1. **No celular:** aba **Pessoas** → **Convidar a família**. Aparece
   **"Seu código de convite"**, por exemplo `K7P-2QX`.
2. **No Vigi Família (navegador):** crie a conta com o e-mail **+familia**, toque
   em **"Acompanhar uma pessoa"** e digite o código.
3. **No celular:** aparece *"Uma pessoa quer acompanhar você."* Toque em
   **Ver o pedido** e depois em **Permitir**.
4. O painel passa a mostrar a pessoa acompanhada.

## 4. Roteiro de testes

Para não esperar uma hora, use um intervalo de **1 minuto**: aba **Modos** →
toque em **Rotina padrão** → diminua o intervalo até **1 min** → **Começar a
vigiar**. Com 1 minuto, a escada inteira leva 2 minutos:

| Momento | Estado | No celular |
|---|---|---|
| 0:00 | Vigiando | Anel de tempo, horário do próximo check-in |
| 1:00 | Sua vez | Tela Âmbar "Está tudo bem?", som suave, botão **Estou bem** |
| 1:40 | Última chamada | Alarme e vibração longa; tela cheia mesmo bloqueado |
| 2:00 | Alerta | Tela vermelha: quem foi avisado e a que horas |
| 4:00 | (servidor) | Se o celular não avisou, o servidor avisa a família |

No modo Rotina normal (1 h) a tolerância é de 15 minutos: 15:00 chamada, 15:10
última chamada, 15:15 contatos avisados.

| # | Ação (no celular) | Resultado esperado |
|---|---|---|
| 1 | Aba **Início** → **Começar a vigiar** | Coruja de olhos abertos, anel de tempo e o horário do próximo check-in; o painel mostra **"… está bem."** |
| 2 | Toque em **Estou bem agora** | A coruja pisca ("Que bom"), o anel recomeça; o painel atualiza "Confirmou às…" |
| 3 | **Pedir ajuda** (rodapé) → segure o botão por **3 segundos** | Contagem 3, 2, 1 com vibração; SMS com o endereço e o link do mapa chega ao contato; a tela mostra quem recebeu; o painel fica **vermelho**, com alarme e **"Ver onde … está"** |
| 4 | Toque rápido no botão de ajuda (sem segurar) | Nada é enviado: "Toques rápidos não pedem ajuda por engano." |
| 5 | **Estou seguro, cancelar o pedido** → confirme | O contato recebe um segundo SMS dizendo que está tudo bem; o painel volta ao normal |
| 6 | Vigie com **1 min** e **não responda** | 1:00 chamada Âmbar; 1:40 alarme de última chamada; 2:00 SMS enviado e o painel mostra **"… não respondeu ao check-in."** |
| 7 | Repita o teste 6 e toque em **Estou bem** durante a chamada | Nenhum SMS é enviado; a vigília recomeça |
| 8 | Repita o teste 6 e toque em **Preciso de mais 10 minutos** | O prazo é estendido uma única vez; na chamada seguinte o botão não aparece mais |
| 9 | Com a chamada tocando e a tela bloqueada, use os botões da **notificação** ("Estou bem" / "+10 min") | Mesmo efeito dos botões do app |
| 10 | Vigie com 1 min e **desligue o celular** (ou ative o modo avião) | Em até ~5 min o **servidor** detecta a falta de resposta e o painel mostra a emergência (sem SMS, pois o celular está desligado) |
| 11 | Aba **Modos** → **Sono** | O app troca para o tema noturno (escuro, sem branco puro) e mostra o novo horário antes de confirmar |
| 12 | Adicione o **widget** Vigi (2x2) na tela inicial do Android | Mostra a coruja e o horário do próximo check-in. Na chamada, o widget inteiro fica Âmbar com **"Estou bem"**: um toque confirma |
| 13 | Tire uma permissão nas configurações do Android (ex.: notificações) e volte ao app | Faixa Âmbar no topo da tela inicial dizendo o que falta, com o botão **Permitir** |
| 14 | Aumente a **fonte do sistema** para o máximo | Nenhum texto cortado; os botões principais continuam visíveis |
| 15 | Aba **Pessoas** → **Ver quem acompanha você** → **Remover** | A pessoa some do painel da família |

## 5. Problemas comuns

| Sintoma | O que fazer |
|---|---|
| App pede **UUID do familiar** | É uma versão antiga. Desinstale e instale o APK mais recente. |
| SMS não chega | Verifique sinal da operadora e saldo; SMS internacional pode ser bloqueado pela operadora. Confira a permissão em **Pessoas → Ver permissões**. |
| O botão "Começar a vigiar" pede para escolher uma pessoa | Cadastre uma pessoa de vigília (passo 2). |
| "Código Vigi não encontrado" | Confira as 6 letras/números em **Pessoas → Convidar a família** no celular. |
| Painel não atualiza | Recarregue a página com **Ctrl + Shift + R**. |
| Alarme atrasa ou não toca com o app fechado | Abra **Pessoas → Ver permissões** e permita **Alarmes**, **Alarme em tela cheia** e **Bateria sem restrição**. |
| A família recebe o alerta enquanto a chamada ainda toca | O banco está sem a migration `20261112000000_state_ladder` (veja a seção 6). |

## 6. Para quem administra o Supabase

Para criar contas de teste já confirmadas (sem e-mail), use o script
[`scripts/sql/criar_usuarios_teste.sql`](../scripts/sql/criar_usuarios_teste.sql)
no **SQL Editor** do Supabase, preenchendo os campos marcados com ✏️.

Depois de atualizar o app para a versão 2.1, aplique a migration da escada de
estados e publique de novo a função de push:

```bash
supabase db push
supabase functions deploy notify-emergency-contacts --use-api
```

Para verificar a infraestrutura do dead man's switch:

```sql
select public.guardiao_health();
```
