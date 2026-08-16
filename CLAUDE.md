PROTOCOLO DE EXECUÇÃO — PROJETO GUARDIÃO
=========================================
Você é o agente responsável por implementar o projeto Guardião seguindo, sem desvio, o documento abaixo desta seção (Decisões Arquiteturais + Stages 0 a 13). As regras a seguir são absolutas e têm prioridade sobre qualquer atalho que pareça razoável no momento.

REGRA-MÃE
---------
Nenhuma etapa é considerada concluída pela sua própria afirmação. Uma Stage só está pronta quando TODOS os itens da "Definição de Pronto" daquela Stage foram verificados por um comando real, executado por você, nesta sessão — e você mostrou a saída real desse comando. "Deve estar funcionando" não é evidência. "Rodei `flutter test` e a saída foi esta: [colar saída]" é evidência. Se você não rodou o comando, o item não está feito, mesmo que o código pareça correto.

LOOP OBRIGATÓRIO, POR STAGE, NESTA ORDEM EXATA
------------------------------------------------
Para cada Stage, na ordem 0 → 13, sem pular nenhuma e sem trabalhar em duas ao mesmo tempo:
1. LEIA a seção da Stage inteira antes de escrever qualquer código.
2. Quando a Stage descrever testes ANTES da implementação (unitários de domain, principalmente): escreva os testes primeiro, rode, CONFIRME que falham pelo motivo certo (não por erro de sintaxe/import), e faça um commit `test:` isolado antes de implementar. Isso cria um checkpoint no Git — se depois você alterar um teste pra fazê-lo passar em vez de corrigir a implementação, o diff expõe isso.
3. IMPLEMENTE o necessário pra Stage, seguindo a estrutura de camadas (domain/data/presentation) e os ADRs sem exceção.
4. RODE, sem pular nenhum, todos os comandos listados na seção "Testes da etapa" daquela Stage.
5. Se QUALQUER comando falhar: conserte a implementação e repita o passo 4. Máximo de 5 tentativas de correção pro mesmo erro — na 6ª falha consecutiva do mesmo teste, PARE e reporte ao humano o que tentou e por que não resolveu. Não entre em loop silencioso. Não contorne o teste pra fazer passar.
6. Só quando 100% dos itens de "Definição de Pronto" estiverem verdes, marque a Stage como concluída no checklist consolidado (Seção "Checklist e Rastreabilidade") e feche com um commit `feat:` (ou `chore:`/`docs:` quando for o caso).
7. Encerre o contexto antes da próxima Stage (`/clear` no Claude Code, ou nova sessão). O checklist commitado no Git é a memória entre etapas — não a conversa. Contexto acumulado degrada a qualidade das etapas seguintes; comece cada Stage com a leitura do documento, não com o histórico da anterior.

O QUE VOCÊ NUNCA FAZ, EM NENHUMA CIRCUNSTÂNCIA
------------------------------------------------
- Nunca marca um item de "Definição de Pronto" como feito sem ter rodado o comando que o verifica NESTA sessão.
- Nunca enfraquece, comenta, deleta ou marca como skip um teste pra fazer a suíte passar. Se genuinely achar que um teste está errado, PARE e explique o motivo ao humano antes de tocar nele.
- Nunca substitui uma integração real (Supabase, FCM, WorkManager) por uma simulação permanente só pra "destravar" e seguir em frente. Mock é legítimo DENTRO de um teste unitário (é o padrão descrito em cada Stage); não é legítimo como substituto silencioso da funcionalidade de verdade no caminho de produção.
- Nunca se desvia de um ADR sem antes escrever um novo ADR explicando por quê, no mesmo formato dos existentes. Decisão não documentada não aconteceu.
- Nunca avança pra próxima Stage com a atual parcialmente pronta "porque o resto é fácil de voltar depois". Não é — foi exatamente esse hábito que produziu o código legado que motivou este documento existir.
- Nunca inventa números, taxas de sucesso ou resultados pra preencher a Seção 5 do TCC. Todo dado quantitativo citado vem de um comando ou de um teste de campo real, documentado.

QUANDO PARAR E PERGUNTAR AO HUMANO (só nestes dois casos)
------------------------------------------------------------
1. A ação é destrutiva ou irreversível fora do ambiente local: deletar dados de produção, forçar push em `main`, publicar em loja, girar credenciais reais.
2. A Stage exige uma decisão de produto que nenhum ADR cobre (ex.: um texto de UI específico, um valor de negócio não especificado). Nesse caso, proponha uma opção padrão razoável, declare a suposição por escrito no commit ou no PR, e siga — só interrompa de verdade se a ambiguidade puder invalidar trabalho de mais de uma Stage caso você escolha errado.
Fora desses dois casos, autonomia total pra prosseguir sem perguntar.

DEFINIÇÃO OPERACIONAL DE "PERFEIÇÃO" NESTE PROJETO
------------------------------------------------------
Uma Stage só está perfeita quando, simultaneamente:
[ ] `flutter analyze` retorna 0 issues
[ ] `dart format --output=none --set-exit-if-changed .` não aponta diffs
[ ] 100% dos testes descritos na Stage passam, nenhum marcado `skip`
[ ] Cobertura domain/data ≥ 80%, presentation ≥ 60% (ver ADR-004)
[ ] Nenhum `TODO`, `FIXME` ou placeholder no código entregue da Stage
[ ] Todos os itens de "Definição de Pronto" verificados com comando real
[ ] CI (GitHub Actions) verde no commit que fecha a Stage
Se qualquer um destes estiver vermelho, a Stage NÃO está pronta — sem exceção, sem "está quase", sem arredondar pra cima.
