import 'package:flutter/material.dart';

import '../services/system_health_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/vigi_tokens.dart';

/// Texto e botão de cada problema de saúde do sistema.
extension HealthIssueCopy on HealthIssue {
  /// O problema, em negrito.
  String get title => switch (this) {
    HealthIssue.noContacts => 'Ninguém será avisado.',
    HealthIssue.notificationsBlocked => 'As notificações estão bloqueadas.',
    HealthIssue.smsDenied => 'O Vigi não pode enviar SMS.',
    HealthIssue.locationDenied => 'A localização está desligada.',
    HealthIssue.batteryOptimized => 'A economia de bateria está ligada.',
    HealthIssue.offline => 'Sem internet.',
  };

  /// O que isso significa para a pessoa.
  String get detail => switch (this) {
    HealthIssue.noContacts =>
      'O Vigi só começa a vigiar depois que você escolher pelo menos uma '
          'pessoa.',
    HealthIssue.notificationsBlocked => 'Sem elas, o Vigi não consegue chamar.',
    HealthIssue.smsDenied => 'Sem isso, ninguém é avisado quando você precisa.',
    HealthIssue.locationDenied =>
      'Quem for avisado não vai saber onde você está.',
    HealthIssue.batteryOptimized =>
      'O celular pode fechar o Vigi enquanto ele vigia.',
    HealthIssue.offline =>
      'O Vigi continua vigiando e avisa seus contatos por SMS.',
  };

  /// Botão que leva direto à correção. `null` = nada a fazer agora.
  String? get action => switch (this) {
    HealthIssue.noContacts => 'Escolher',
    HealthIssue.notificationsBlocked => 'Permitir',
    HealthIssue.smsDenied => 'Permitir',
    HealthIssue.locationDenied => 'Permitir',
    HealthIssue.batteryOptimized => 'Ajustar',
    HealthIssue.offline => null,
  };
}

/// Faixa de saúde do sistema: só aparece quando algo compromete a proteção.
///
/// É âmbar porque é a vez da pessoa agir, não vermelha, porque ainda não é
/// socorro.
class HealthBanner extends StatelessWidget {
  const HealthBanner({super.key, required this.issue, this.onFix});

  final HealthIssue issue;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final action = issue.action;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VigiSpace.x4),
        decoration: BoxDecoration(
          color: VigiColors.ambar100,
          borderRadius: BorderRadius.circular(VigiRadius.md),
        ),
        child: Builder(
          builder: (context) {
            final message = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.error_rounded,
                    color: VigiColors.ambar700,
                    size: VigiSizes.icon,
                  ),
                ),
                const SizedBox(width: VigiSpace.x3),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${issue.title} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: issue.detail),
                      ],
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: VigiColors.petroleo800,
                    ),
                  ),
                ),
              ],
            );
            if (action == null || onFix == null) return message;

            final button = FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: VigiColors.petroleo800,
                foregroundColor: VigiColors.linho100,
                minimumSize: const Size(96, VigiSizes.touch),
                padding: const EdgeInsets.symmetric(horizontal: VigiSpace.x4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VigiRadius.sm),
                ),
                textStyle: AppTypography.label,
              ),
              onPressed: onFix,
              child: Text(action),
            );

            // Com a fonte do sistema ampliada, o botão desce para a linha
            // de baixo em vez de espremer o texto.
            final large = MediaQuery.textScalerOf(context).scale(10) > 13;
            if (large) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  message,
                  const SizedBox(height: VigiSpace.x3),
                  Align(alignment: Alignment.centerRight, child: button),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: message),
                const SizedBox(width: VigiSpace.x3),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}
