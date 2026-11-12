import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../domain/entities/family_link_entity.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

String formatLinkCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;

/// Tela "Família" da pessoa acompanhada: compartilhar o código de convite,
/// autorizar quem pode acompanhá-la e remover acessos. O vínculo só existe
/// se ela tocar em "Permitir".
class FamilyPanelPage extends StatefulWidget {
  const FamilyPanelPage({super.key});

  @override
  State<FamilyPanelPage> createState() => _FamilyPanelPageState();
}

class _FamilyPanelPageState extends State<FamilyPanelPage> {
  @override
  void initState() {
    super.initState();
    context.read<FamilyBloc>().add(const LoadFamilyLinksRequested());
  }

  Future<void> _shareWhatsApp(String code) async {
    const url = AppConfig.familyWebUrl;
    final text =
        'Oi! Este é meu código de convite no Vigi: ${formatLinkCode(code)}. '
        '${url.isNotEmpty ? 'Entre em $url, ' : 'Abra o Vigi Família, '}'
        'toque em "Acompanhar uma pessoa" e digite o código.';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: formatLinkCode(code)));
    if (!mounted) return;
    showVigiMessage(context, 'Código copiado.');
  }

  Future<void> _confirmRemove(FamilyLinkEntity link) async {
    final bloc = context.read<FamilyBloc>();
    final name = VigiText.firstName(link.viewerUserName);
    final who = name.isEmpty ? 'essa pessoa' : name;
    final ok = await showVigiConfirm(
      context,
      title: 'Remover $who?',
      message:
          '${name.isEmpty ? 'Essa pessoa' : name} deixa de ver se você está '
          'bem. Você pode autorizar de novo depois, se quiser.',
      confirmLabel: 'Remover $who',
    );
    if (ok) bloc.add(RemoveFamilyLinkRequested(link.id));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Família'),
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyFailure) {
            showVigiMessage(context, state.message);
          } else if (state is FamilyActionSuccess) {
            showVigiMessage(context, state.message);
          }
        },
        buildWhen: (_, current) =>
            current is FamilyLoaded ||
            current is FamilyLoading ||
            current is FamilyInitial,
        builder: (context, state) {
          if (state is! FamilyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                VigiSpace.screen,
                VigiSpace.x2,
                VigiSpace.screen,
                VigiSpace.x6,
              ),
              children: [
                for (final request in state.pendingRequests) ...[
                  _RequestCard(link: request),
                  const SizedBox(height: VigiSpace.x4),
                ],
                _CodeCard(
                  code: state.myCode,
                  onShare: _shareWhatsApp,
                  onCopy: _copy,
                ),
                const SizedBox(height: VigiSpace.block),
                Text(
                  'Quem acompanha você',
                  style: AppTypography.h3.copyWith(color: palette.text),
                ),
                const SizedBox(height: VigiSpace.x2),
                if (state.followers.isEmpty)
                  Text(
                    'Ninguém ainda. Envie o seu código para alguém da '
                    'família.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: palette.textMuted,
                    ),
                  )
                else
                  for (final f in state.followers) ...[
                    Semantics(
                      button: true,
                      label:
                          '${f.viewerUserName ?? 'Familiar'}, vê se você '
                          'está bem. Toque para remover.',
                      onTap: () => _confirmRemove(f),
                      excludeSemantics: true,
                      child: AppCard(
                        onTap: () => _confirmRemove(f),
                        child: Row(
                          children: [
                            ContactAvatar(name: f.viewerUserName ?? 'Familiar'),
                            const SizedBox(width: VigiSpace.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.viewerUserName ?? 'Familiar',
                                    style: AppTypography.h3.copyWith(
                                      color: palette.text,
                                    ),
                                  ),
                                  Text(
                                    'Vê se você está bem. Toque para remover.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VigiSizes.touchGap),
                  ],
                const SizedBox(height: VigiSpace.block),
                AppPrimaryButton(
                  text: 'Eu quero acompanhar alguém',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/family-dashboard'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.code,
    required this.onShare,
    required this.onCopy,
  });

  final String? code;
  final Future<void> Function(String) onShare;
  final Future<void> Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final formatted = code == null ? null : formatLinkCode(code!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu código de convite',
            style: AppTypography.h3.copyWith(color: palette.text),
          ),
          const SizedBox(height: VigiSpace.x2),
          Semantics(
            label: formatted == null
                ? 'Código indisponível'
                : 'Código ${formatted.split('').join(' ')}',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SelectableText(
                formatted ?? '— — —',
                style: AppTypography.display.copyWith(
                  color: palette.text,
                  fontSize: 44,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: VigiSpace.x2),
          Text(
            'Envie este código para quem vai acompanhar você. Essa pessoa '
            'só vê se você está bem; a sua localização só é enviada em um '
            'pedido de ajuda.',
            style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
          ),
          if (code != null) ...[
            const SizedBox(height: VigiSpace.x4),
            AppPrimaryButton(
              text: 'Enviar pelo WhatsApp',
              onPressed: () => onShare(code!),
            ),
            const SizedBox(height: VigiSizes.touchGap),
            AppPrimaryButton(
              text: 'Copiar código',
              variant: AppButtonVariant.outline,
              onPressed: () => onCopy(code!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pedido pendente: é a vez da pessoa (âmbar), porque alguém espera a
/// autorização dela.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.link});

  final FamilyLinkEntity link;

  @override
  Widget build(BuildContext context) {
    final name = link.viewerUserName?.trim().isNotEmpty ?? false
        ? link.viewerUserName!.trim()
        : 'Alguém da família';
    const text = VigiColors.petroleo800;

    return AppCard(
      backgroundColor: VigiColors.ambar100,
      borderColor: VigiColors.ambar100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$name quer acompanhar você',
            style: AppTypography.h3.copyWith(color: text),
          ),
          const SizedBox(height: VigiSpace.x2),
          Text(
            'Essa pessoa vai ver se você está bem e a hora do seu último '
            'check-in. A sua localização só é enviada se você pedir ajuda '
            'ou não responder a um check-in.',
            style: AppTypography.bodyMedium.copyWith(color: text),
          ),
          const SizedBox(height: VigiSpace.x4),
          AppPrimaryButton(
            text: 'Permitir',
            variant: AppButtonVariant.amber,
            onPressed: () => context.read<FamilyBloc>().add(
              RespondFamilyLinkRequested(linkId: link.id, accept: true),
            ),
          ),
          const SizedBox(height: VigiSizes.touchGap),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: text,
              side: const BorderSide(color: text, width: 2),
            ),
            onPressed: () => context.read<FamilyBloc>().add(
              RespondFamilyLinkRequested(linkId: link.id, accept: false),
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
}
