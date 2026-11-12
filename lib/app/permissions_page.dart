import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/system_health_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/vigi_palette.dart';
import '../core/theme/vigi_tokens.dart';
import '../core/widgets/app_primary_button.dart';
import '../core/widgets/health_banner.dart';
import '../core/widgets/vigi_mascot.dart';
import '../injection/injection_container.dart';
import 'system_health_cubit.dart';

/// Lembra se a pessoa já passou pela tela "Permissões".
abstract final class PermissionsIntro {
  static const String _key = 'vigi_permissions_intro_seen';

  static SharedPreferences? get _prefs =>
      sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null;

  /// Primeira vez neste aparelho: a tela ainda não foi mostrada.
  static bool get pending {
    final prefs = _prefs;
    if (prefs == null) return false;
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> markSeen() async {
    await _prefs?.setBool(_key, true);
  }
}

/// Tela "Permissões": explica, uma a uma e em linguagem clara, o que o Vigi
/// precisa do celular e para quê, antes de o sistema perguntar.
///
/// Cada item mostra o estado ("Permitido") ou o botão que resolve. Nada é
/// pedido sem a pessoa tocar, e ela pode continuar sem permitir tudo: o que
/// faltar aparece depois no topo da tela inicial (princípio "falhar alto").
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<SystemHealthCubit>().refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // O diálogo do sistema (ou a tela de configurações) fechou: confere de
    // novo o que foi permitido.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<SystemHealthCubit>().refresh());
    }
  }

  Future<void> _finish() async {
    await PermissionsIntro.markSeen();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final cubit = context.watch<SystemHealthCubit>();
    final kinds = cubit.permissionKinds;
    final missing = cubit.state.where(kinds.contains).toSet();
    final allGranted = missing.isEmpty;
    // Com a fonte grande, o aviso rola junto com a lista: fixo, ele tomaria
    // quase metade da tela e esconderia as permissões.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final note = Semantics(
      liveRegion: true,
      child: Text(
        allGranted
            ? 'Tudo certo: o Vigi tem o que precisa.'
            : 'Você pode permitir depois. O Vigi avisa na tela inicial o que '
                  'estiver faltando.',
        style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
      ),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(PermissionsIntro.markSeen());
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    VigiSpace.screen,
                    VigiSpace.x6,
                    VigiSpace.screen,
                    VigiSpace.x4,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: VigiMascot(
                        state: allGranted
                            ? VigiState.vigiando
                            : VigiState.suaVez,
                        size: 96,
                      ),
                    ),
                    const SizedBox(height: VigiSpace.x3),
                    Semantics(
                      header: true,
                      child: Text(
                        'Para o Vigi cuidar de você',
                        style: AppTypography.h1.copyWith(color: palette.text),
                      ),
                    ),
                    const SizedBox(height: VigiSpace.x2),
                    Text(
                      'O Vigi pede só o que precisa, e diz para quê. Você '
                      'pode mudar de ideia quando quiser.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: VigiSpace.x6),
                    for (final kind in kinds) ...[
                      _PermissionCard(
                        issue: kind,
                        granted: !missing.contains(kind),
                        onAllow: () => cubit.fix(kind),
                      ),
                      const SizedBox(height: VigiSizes.touchGap),
                    ],
                    if (largeText) ...[
                      const SizedBox(height: VigiSpace.x2),
                      note,
                    ],
                  ],
                ),
              ),
              // A linha marca onde a lista passa por baixo do rodapé fixo.
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VigiSpace.screen,
                    VigiSpace.x3,
                    VigiSpace.screen,
                    VigiSpace.screen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!largeText) ...[
                        note,
                        const SizedBox(height: VigiSpace.x3),
                      ],
                      AppPrimaryButton(text: 'Continuar', onPressed: _finish),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma permissão: ícone e nome, para que serve, e o estado ou o botão.
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.issue,
    required this.granted,
    required this.onAllow,
  });

  final HealthIssue issue;
  final bool granted;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    // Pendente é a vez da pessoa agir: âmbar, como na faixa de saúde.
    final background = granted ? palette.surface : VigiColors.ambar100;
    final foreground = granted ? palette.text : VigiColors.petroleo800;
    final muted = granted ? palette.textMuted : VigiColors.petroleo800;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(VigiSpace.x4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(VigiRadius.md),
          border: Border.all(color: granted ? palette.border : background),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    issue.permissionIcon,
                    color: foreground,
                    size: VigiSizes.icon,
                  ),
                ),
                const SizedBox(width: VigiSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.permissionName,
                        style: AppTypography.h3.copyWith(color: foreground),
                      ),
                      const SizedBox(height: VigiSpace.x1),
                      Text(
                        issue.permissionPurpose,
                        style: AppTypography.bodyMedium.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VigiSpace.x3),
            if (granted)
              // Estado por ícone e texto, não só por cor.
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.text,
                    size: VigiSizes.iconMin,
                  ),
                  const SizedBox(width: VigiSpace.x2),
                  Text(
                    'Permitido',
                    style: AppTypography.label.copyWith(color: palette.text),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: VigiColors.petroleo800,
                    foregroundColor: VigiColors.linho100,
                    minimumSize: const Size(140, VigiSizes.touch),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VigiRadius.sm),
                    ),
                    textStyle: AppTypography.label,
                  ),
                  onPressed: onAllow,
                  child: Text(issue.permissionAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
