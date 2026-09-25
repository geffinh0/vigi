import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/family_link_entity.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

String formatLinkCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;

/// Tela "Família" do idoso: compartilhar o código VIGI, autorizar quem pode
/// acompanhá-lo e remover acessos. Tudo com poucos toques e textos diretos.
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
        'Oi! Este é meu código no VIGI: ${formatLinkCode(code)}. '
        '${url.isNotEmpty ? 'Entre em $url, ' : 'Abra o VIGI Família, '}'
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado!')));
  }

  Future<void> _confirmRemove(FamilyLinkEntity link) async {
    final bloc = context.read<FamilyBloc>();
    final name = link.viewerUserName ?? 'esta pessoa';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover $name?'),
        content: const Text(
          'Ela deixará de ver se você está bem. Você pode autorizar de novo '
          'depois, se quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.panico),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(RemoveFamilyLinkRequested(link.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(title: const Text('Família')),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyFailure || state is FamilyActionSuccess) {
            final isError = state is FamilyFailure;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isError
                      ? state.message
                      : (state as FamilyActionSuccess).message,
                ),
                backgroundColor: isError
                    ? AppColors.panico
                    : AppColors.petroleo,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is FamilyLoaded ||
            current is FamilyLoading ||
            current is FamilyInitial,
        builder: (context, state) {
          if (state is! FamilyLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.petroleo),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final request in state.pendingRequests) ...[
                _RequestCard(link: request),
                const SizedBox(height: 16),
              ],
              _CodeCard(
                code: state.myCode,
                onShare: _shareWhatsApp,
                onCopy: _copy,
              ),
              const SizedBox(height: 24),
              Text(
                'Quem acompanha você',
                style: AppTypography.h3.copyWith(color: AppColors.petroleo),
              ),
              const SizedBox(height: 8),
              if (state.followers.isEmpty)
                Text(
                  'Ninguém ainda. Envie seu código para um familiar.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.cinzaTexto,
                  ),
                )
              else
                for (final f in state.followers) ...[
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.viewerUserName ?? 'Familiar',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _confirmRemove(f),
                          child: const Text(
                            'Remover',
                            style: TextStyle(color: AppColors.panico),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: 'Eu quero acompanhar alguém',
                icon: Icons.family_restroom,
                variant: AppButtonVariant.outline,
                onPressed: () => context.push('/family-dashboard'),
              ),
            ],
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu código VIGI',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.cinzaTexto,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            code == null ? '— — —' : formatLinkCode(code!),
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(
              color: AppColors.petroleo,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Envie este código para quem vai cuidar de você. '
            'Essa pessoa só verá se você está bem — sua localização só é '
            'enviada em uma emergência.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.cinzaTexto,
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Enviar pelo WhatsApp',
              icon: Icons.send,
              onPressed: () => onShare(code!),
            ),
            const SizedBox(height: 8),
            AppPrimaryButton(
              text: 'Copiar código',
              icon: Icons.copy,
              variant: AppButtonVariant.outline,
              onPressed: () => onCopy(code!),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.link});

  final FamilyLinkEntity link;

  @override
  Widget build(BuildContext context) {
    final name = link.viewerUserName?.trim().isNotEmpty ?? false
        ? link.viewerUserName!.trim()
        : 'Um familiar';
    return AppCard(
      borderColor: AppColors.ambar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$name quer acompanhar você',
            style: AppTypography.h3.copyWith(color: AppColors.petroleo),
          ),
          const SizedBox(height: 8),
          Text(
            'Ela verá se você está bem e a hora do seu último check-in. '
            'Sua localização só é enviada se você pedir socorro ou não '
            'responder a um check-in.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'Permitir',
            icon: Icons.check,
            onPressed: () => context.read<FamilyBloc>().add(
              RespondFamilyLinkRequested(linkId: link.id, accept: true),
            ),
          ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            text: 'Recusar',
            variant: AppButtonVariant.outline,
            onPressed: () => context.read<FamilyBloc>().add(
              RespondFamilyLinkRequested(linkId: link.id, accept: false),
            ),
          ),
        ],
      ),
    );
  }
}
