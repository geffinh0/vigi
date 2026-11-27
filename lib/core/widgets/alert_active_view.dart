import 'package:flutter/material.dart';

import '../services/checkin_messages.dart';
import '../services/emergency_dispatcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/vigi_state.dart';
import '../theme/vigi_tokens.dart';
import '../utils/vigi_text.dart';
import 'app_primary_button.dart';
import 'contact_avatar.dart';
import 'pinned_actions_layout.dart';
import 'vigi_dialogs.dart';
import 'vigi_mascot.dart';

/// Tela de alerta ativo: os contatos foram avisados (pânico ou ausência de
/// resposta).
///
/// A informação mais importante é que alguém foi avisado. A tela diz o que
/// foi feito, lista cada contato com o status da mensagem, mostra a
/// localização como endereço aproximado (não como coordenadas) e deixa o
/// cancelamento claro, mas com confirmação.
///
/// O fundo é Sinal 600 mesmo no tema noturno: uma emergência não respeita o
/// modo escuro.
class AlertActiveView extends StatelessWidget {
  const AlertActiveView({
    super.key,
    required this.contactsFound,
    required this.smsSent,
    required this.at,
    required this.onCancel,
    this.deliveries = const [],
    this.hasLocation = false,
    this.address,
    this.isBusy = false,
  });

  /// Quantos contatos estavam cadastrados. `null` = o envio não foi tentado
  /// (app sem o canal de SMS).
  final int? contactsFound;
  final int smsSent;

  /// Quando os contatos foram avisados.
  final DateTime at;
  final List<ContactDelivery> deliveries;
  final bool hasLocation;
  final String? address;

  /// A pessoa confirmou que está segura.
  final VoidCallback onCancel;
  final bool isBusy;

  String get _summary {
    if (contactsFound == null) {
      return 'Seu pedido foi registrado. Quem acompanha você pelo app já '
          'está sendo avisado.';
    }
    if (contactsFound == 0) {
      return 'Não há ninguém cadastrado para ser avisado. Se puder, ligue '
          'para alguém de confiança ou para o 192.';
    }
    if (smsSent == 0) {
      return 'Não conseguimos enviar o SMS sozinhos. Confirme o envio no app '
          'de mensagens, ou ligue para alguém de confiança.';
    }
    return CheckinMessages.alertedBody(
      notified: smsSent,
      at: at,
      withLocation: hasLocation,
    );
  }

  String get _where {
    if (!hasLocation) return 'Sem localização: o GPS não respondeu a tempo.';
    final place = address?.trim() ?? '';
    return place.isEmpty ? 'Sua localização foi enviada.' : 'Perto de $place';
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final names = deliveries.where((d) => d.sent).map((d) => d.name).toList();
    final ok = await showVigiConfirm(
      context,
      title: 'Cancelar o pedido de ajuda?',
      message: names.isEmpty
          ? 'Use só se estiver tudo bem com você.'
          : 'Vamos avisar ${VigiText.joinNames(names)} de que está tudo bem '
                'com você.',
      confirmLabel: 'Estou seguro, cancelar',
    );
    if (ok) onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final style = VigiStateStyle.of(VigiState.alerta);
    const white = VigiColors.branco;

    return ColoredBox(
      color: style.background,
      child: PinnedActionsLayout(
        content: [
          const SizedBox(height: VigiSpace.x4),
          const Center(
            child: VigiMascot(state: VigiState.alerta, onSignal: true),
          ),
          const SizedBox(height: VigiSpace.x4),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              CheckinMessages.alertedTitle,
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(color: white),
            ),
          ),
          const SizedBox(height: VigiSpace.x3),
          Text(
            _summary,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(color: white),
          ),
          if (deliveries.isNotEmpty) ...[
            const SizedBox(height: VigiSpace.x6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VigiSpace.x4,
                vertical: VigiSpace.x2,
              ),
              decoration: BoxDecoration(
                color: VigiColors.sinal700,
                borderRadius: BorderRadius.circular(VigiRadius.md),
              ),
              child: Column(
                children: [
                  for (final d in deliveries) _DeliveryRow(delivery: d),
                ],
              ),
            ),
          ],
          if (contactsFound != 0) ...[
            const SizedBox(height: VigiSpace.x4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: white,
                    size: VigiSizes.iconMin,
                  ),
                ),
                const SizedBox(width: VigiSpace.x2),
                Expanded(
                  child: Text(
                    _where,
                    style: AppTypography.bodyMedium.copyWith(
                      color: white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
        actions: [
          AppPrimaryButton(
            text: 'Estou seguro, cancelar o pedido',
            variant: AppButtonVariant.onSignal,
            isLoading: isBusy,
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final ContactDelivery delivery;

  @override
  Widget build(BuildContext context) {
    const white = VigiColors.branco;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VigiSpace.x2),
        child: Row(
          children: [
            ContactAvatar(
              name: delivery.name,
              size: 40,
              background: VigiColors.sinal600,
              foreground: white,
            ),
            const SizedBox(width: VigiSpace.x3),
            // Nome à esquerda e status à direita; com a fonte ampliada o
            // status desce para a linha de baixo em vez de ser cortado.
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VigiSpace.x2,
                children: [
                  Text(
                    VigiText.firstName(delivery.name),
                    style: AppTypography.label.copyWith(color: white),
                  ),
                  Text(
                    delivery.sent ? 'SMS enviado' : 'Não enviado',
                    style: AppTypography.bodyMedium.copyWith(color: white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
