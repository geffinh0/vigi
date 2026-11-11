import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/checkin_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_state.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/alert_active_view.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/pinned_actions_layout.dart';
import '../../../../core/widgets/status_ring.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../../../contacts/presentation/bloc/contacts_state.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

/// Tela cheia dos degraus urgentes da escada:
///
/// - **Sua vez**: "Tudo bem por aí, Lúcia?", com o próximo passo por extenso
///   e o botão "Estou bem" na metade inferior, onde o polegar alcança.
/// - **Última chamada**: a mesma tela, mais intensa, com o alarme tocando.
/// - **Alerta**: os contatos foram avisados.
///
/// Dizer que está bem nunca pode ser difícil: um toque, sem confirmação.
class CheckinAlertPage extends StatelessWidget {
  const CheckinAlertPage({super.key, this.now});

  /// Relógio injetável para os testes.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // A pessoa responde com um dos botões; "voltar" não esconde a chamada.
      canPop: false,
      child: BlocConsumer<CheckinBloc, CheckinState>(
        listenWhen: (previous, current) =>
            current is CheckinMonitoring || current is CheckinIdle,
        listener: (context, state) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        buildWhen: (previous, current) =>
            current is CheckinCalling || current is CheckinAlertActive,
        builder: (context, state) {
          if (state is CheckinAlertActive) {
            return Scaffold(
              body: AlertActiveView(
                contactsFound: state.contactsFound,
                smsSent: state.smsSent,
                at: state.alertedAt,
                deliveries: state.deliveries,
                hasLocation: state.hasLocation,
                address: state.address,
                onCancel: () => context.read<CheckinBloc>().add(
                  const ConfirmCheckinRequested(),
                ),
              ),
            );
          }
          if (state is CheckinCalling) {
            return _CallView(state: state, now: now ?? DateTime.now);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _CallView extends StatefulWidget {
  const _CallView({required this.state, required this.now});

  final CheckinCalling state;
  final DateTime Function() now;

  @override
  State<_CallView> createState() => _CallViewState();
}

class _CallViewState extends State<_CallView> {
  Timer? _clock;
  bool _lastMinute = false;
  bool? _announcedLastCall;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _checkTime());
    _checkTime();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announce();
  }

  @override
  void didUpdateWidget(covariant _CallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _announce();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _checkTime() {
    final left = widget.state.escalatesAt.difference(widget.now());
    final lastMinute = left <= const Duration(minutes: 1);
    if (lastMinute != _lastMinute && mounted) {
      setState(() => _lastMinute = lastMinute);
    }
  }

  String get _firstName {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated
        ? VigiText.firstName(auth.user.fullName)
        : '';
  }

  List<String> get _contactNames {
    final contacts = context.read<ContactsBloc>().state;
    return contacts is ContactsLoaded
        ? contacts.contacts.map((c) => c.name).toList()
        : const [];
  }

  String get _question => widget.state.lastCall
      ? CheckinMessages.lastCallTitle(_firstName)
      : CheckinMessages.question(_firstName);

  String get _consequence =>
      CheckinMessages.consequence(widget.state.escalatesAt, _contactNames);

  /// A chamada é anunciada sozinha pelo leitor de tela ao entrar no estado.
  void _announce() {
    if (_announcedLastCall == widget.state.lastCall) return;
    _announcedLastCall = widget.state.lastCall;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        '$_question $_consequence',
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final vigiState = state.vigiState;
    final style = VigiStateStyle.of(vigiState);
    final duration = context.reduceMotion
        ? Duration.zero
        : VigiMotion.stateChange;

    return AnimatedContainer(
      duration: duration,
      curve: VigiMotion.stateCurve,
      color: style.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PinnedActionsLayout(
          content: [
            const SizedBox(height: VigiSpace.x6),
            Center(
              child: StatusRing(
                progress: 1,
                state: vigiState,
                size: 200,
                // No último minuto o anel ganha uma borda Sinal: é o único
                // momento em que Âmbar e vermelho aparecem juntos.
                color: _lastMinute ? VigiColors.sinal500 : null,
                fillColor: style.background,
                trackColor: style.ring,
                child: VigiMascot(state: vigiState),
              ),
            ),
            const SizedBox(height: VigiSpace.x8),
            Semantics(
              header: true,
              child: Text(
                _question,
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(color: style.onBackground),
              ),
            ),
            const SizedBox(height: VigiSpace.x3),
            Text(
              _consequence,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: style.onBackground,
              ),
            ),
          ],
          actions: [
            AppPrimaryButton(
              text: 'Estou bem',
              // Sobre o Âmbar 300 da última chamada, o botão passa a
              // Petróleo para continuar impossível de errar.
              variant: state.lastCall
                  ? AppButtonVariant.primary
                  : AppButtonVariant.amber,
              size: AppButtonSize.call,
              semanticsHint: 'Confirma que está tudo bem',
              onPressed: () => context.read<CheckinBloc>().add(
                const ConfirmCheckinRequested(),
              ),
            ),
            if (state.canSnooze) ...[
              const SizedBox(height: VigiSizes.touchGap),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: style.onBackground,
                  minimumSize: const Size.fromHeight(VigiSizes.touch),
                ),
                onPressed: () => context.read<CheckinBloc>().add(
                  const SnoozeCheckinRequested(),
                ),
                child: Text(
                  'Preciso de mais 10 minutos',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: style.onBackground,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
