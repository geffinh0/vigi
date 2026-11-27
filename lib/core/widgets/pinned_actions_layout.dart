import 'package:flutter/material.dart';

import '../theme/vigi_tokens.dart';

/// Tela cheia com as ações presas na metade inferior, onde o polegar
/// alcança.
///
/// O conteúdo de cima rola se a fonte do sistema crescer, mas os botões
/// nunca saem da tela: em uma chamada ou em um alerta, a resposta precisa
/// estar sempre à vista.
class PinnedActionsLayout extends StatelessWidget {
  const PinnedActionsLayout({
    super.key,
    required this.content,
    required this.actions,
  });

  /// Conteúdo centralizado (mascote, pergunta, texto).
  final List<Widget> content;

  /// Botões presos ao rodapé, de cima para baixo.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VigiSpace.screen,
                  VigiSpace.screen,
                  VigiSpace.screen,
                  VigiSpace.x4,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - VigiSpace.screen - VigiSpace.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VigiSpace.screen,
              0,
              VigiSpace.screen,
              VigiSpace.screen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }
}
