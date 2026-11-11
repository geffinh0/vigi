import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/checkin_messages.dart';
import '../../core/services/system_health_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vigi_palette.dart';
import '../../core/theme/vigi_tokens.dart';
import '../../core/utils/vigi_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/contact_avatar.dart';
import '../../core/widgets/health_banner.dart';
import '../../core/widgets/status_ring.dart';
import '../../core/widgets/vigi_mascot.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/checkin/domain/entities/monitoring_mode_entity.dart';
import '../../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../../features/checkin/presentation/bloc/checkin_event.dart';
import '../../features/checkin/presentation/bloc/checkin_state.dart';
import '../../features/checkin/presentation/widgets/mode_icons.dart';
import '../../features/checkin/presentation/widgets/mode_sheets.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/contacts/presentation/bloc/contacts_state.dart';
import '../system_health_cubit.dart';

/// Aba "Início". Hierarquia fixa, de cima para baixo: saudação e modo ativo;
/// o anel com a coruja; o horário do próximo check-in e o botão "Estou bem
/// agora"; as pessoas que serão avisadas. O botão "Pedir ajuda" fica no
/// rodapé fixo da tela.
///
/// No estado normal esta é a tela mais tranquila do celular: cores de fundo,
/// movimento lento, nenhum som.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.onOpenModes,
    required this.onOpenPeople,
    this.now,
  });

  final VoidCallback onOpenModes;
  final VoidCallback onOpenPeople;

  /// Relógio injetável para os testes.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final auth = context.watch<AuthBloc>().state;
    final firstName = auth is AuthAuthenticated
        ? VigiText.firstName(auth.user.fullName)
        : '';

    final contactsState = context.watch<ContactsBloc>().state;
    final contactNames = contactsState is ContactsLoaded
        ? contactsState.contacts.map((c) => c.name).toList()
        : const <String>[];
    final noContacts =
        contactsState is ContactsLoaded && contactsState.contacts.isEmpty;

    final deviceIssues = context.watch<SystemHealthCubit>().state;
    final issues = <HealthIssue>[
      if (noContacts) HealthIssue.noContacts,
      ...deviceIssues,
    ];

    return BlocBuilder<CheckinBloc, CheckinState>(
      builder: (context, state) {
        final (
          MonitoringModeEntity? mode,
          int interval,
          DateTime? deadline,
        ) = switch (state) {
          CheckinMonitoring(
            :final activeMode,
            :final totalSeconds,
            :final nextDeadline,
          ) =>
            (activeMode, totalSeconds ~/ 60, nextDeadline),
          CheckinIdle(:final selectedMode, :final intervalMinutes) => (
            selectedMode,
            intervalMinutes,
            null,
          ),
          _ => (null, 60, null),
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            VigiSpace.screen,
            VigiSpace.x4,
            VigiSpace.screen,
            VigiSpace.x6,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                VigiText.greeting((now ?? DateTime.now)(), firstName),
                style: AppTypography.h2.copyWith(color: palette.text),
              ),
            ),
            const SizedBox(height: VigiSpace.x2),
            Align(
              alignment: Alignment.centerLeft,
              child: _ModeChipButton(
                icon: mode == null ? Icons.home_rounded : ModeIcons.of(mode),
                label: state is CheckinIdle
                    ? 'Vigília pausada'
                    : activeModeLabel(
                        mode,
                        intervalMinutes: interval,
                        deadline: deadline,
                      ),
                onTap: onOpenModes,
              ),
            ),
            for (final issue in issues) ...[
              const SizedBox(height: VigiSpace.x4),
              HealthBanner(
                issue: issue,
                onFix: issue == HealthIssue.noContacts
                    ? onOpenPeople
                    : () => context.read<SystemHealthCubit>().fix(issue),
              ),
            ],
            const SizedBox(height: VigiSpace.block),
            switch (state) {
              CheckinMonitoring() => _Watching(
                state: state,
                contactNames: contactNames,
                onOpenPeople: onOpenPeople,
              ),
              CheckinIdle() => _Resting(state: state),
              CheckinFailure() => const _Resting(state: CheckinIdle()),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: VigiSpace.x16),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        );
      },
    );
  }
}

class _ModeChipButton extends StatelessWidget {
  const _ModeChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return Semantics(
      button: true,
      label: '$label. Trocar de modo.',
      excludeSemantics: true,
      child: Material(
        color: palette.chip,
        borderRadius: BorderRadius.circular(VigiRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VigiSizes.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VigiSpace.x4,
                vertical: VigiSpace.x2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: VigiSizes.iconMin, color: palette.text),
                  const SizedBox(width: VigiSpace.x2),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vigiando (ou Noturno, ou Aliviado): o anel de vigília.
class _Watching extends StatelessWidget {
  const _Watching({
    required this.state,
    required this.contactNames,
    required this.onOpenPeople,
  });

  final CheckinMonitoring state;
  final List<String> contactNames;
  final VoidCallback onOpenPeople;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final vigiState = state.vigiState;
    final deadline = state.nextDeadline;
    final sleep = state.isSleep;

    final status = state.relieved
        ? CheckinMessages.relief(deadline, afterAlert: state.reliefAfterAlert)
        : sleep
        ? 'Vou vigiar enquanto você dorme.'
        : CheckinMessages.nextCheckin(deadline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: StatusRing(
            progress: state.remainingFraction,
            state: vigiState,
            semanticsLabel: VigiText.ringSpoken(
              deadline,
              state.remainingSeconds,
            ),
            child: Padding(
              padding: const EdgeInsets.all(VigiSpace.x6),
              // O conteúdo do anel não pode vazar quando a fonte do sistema
              // cresce: o texto já é grande e encolhe para caber.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.15,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VigiMascot(state: vigiState, size: 88),
                      Text(
                        // Horário absoluto importa: "38 min" exige cálculo,
                        // "até 15:00" não.
                        sleep
                            ? VigiText.clock(deadline)
                            : VigiText.remaining(state.remainingSeconds),
                        style: AppTypography.display.copyWith(
                          color: palette.text,
                        ),
                      ),
                      Text(
                        sleep
                            ? 'próximo check-in'
                            : 'até ${VigiText.clock(deadline)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: palette.textMuted,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: VigiSpace.x6),
        Semantics(
          liveRegion: state.relieved,
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(height: VigiSpace.x6),
        if (state.relieved)
          // Ao tocar, o botão vira "Confirmado" antes de a tela voltar ao
          // normal. Sem diálogo: dizer que está bem nunca pode ser difícil.
          const AppPrimaryButton(
            text: 'Confirmado',
            icon: Icons.check_rounded,
            variant: AppButtonVariant.amber,
          )
        else
          AppPrimaryButton(
            text: 'Estou bem agora',
            variant: AppButtonVariant.outline,
            semanticsHint: 'Confirma que está tudo bem e reinicia o intervalo',
            onPressed: () => context.read<CheckinBloc>().add(
              const ConfirmCheckinRequested(),
            ),
          ),
        const SizedBox(height: VigiSpace.x4),
        WatchersRow(
          names: contactNames,
          text: CheckinMessages.watching(contactNames),
          onTap: onOpenPeople,
        ),
      ],
    );
  }
}

/// Descansando: monitoramento pausado. Coruja de olhos fechados, cinza, sem
/// anel, e um único botão grande. O Vigi não finge estar protegendo quando
/// não está.
class _Resting extends StatelessWidget {
  const _Resting({required this.state});

  final CheckinIdle state;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final mode = state.selectedMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: VigiMascot(state: VigiState.descansando, size: 160),
        ),
        const SizedBox(height: VigiSpace.x4),
        Text(
          'O Vigi está descansando',
          textAlign: TextAlign.center,
          style: AppTypography.h2.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.x2),
        Text(
          'A vigília está pausada: ninguém será avisado se algo acontecer.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.block),
        AppPrimaryButton(
          text: 'Começar a vigiar',
          semanticsHint:
              'Modo ${mode?.shortName ?? 'Rotina'}, check-in a cada '
              '${VigiText.remainingSpoken(state.intervalMinutes * 60)}',
          onPressed: () => context.read<CheckinBloc>().add(
            StartMonitoringRequested(
              modeId: mode?.id ?? 'system-default-routine',
              intervalOverrideMinutes: state.intervalMinutes,
            ),
          ),
        ),
        const SizedBox(height: VigiSpace.x3),
        Text(
          '${mode?.shortName ?? 'Rotina'}: o Vigi pergunta se está tudo bem a '
          'cada ${VigiText.interval(state.intervalMinutes)}.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
