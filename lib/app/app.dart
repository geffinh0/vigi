import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_primary_button.dart';
import '../core/widgets/status_ring.dart';
import '../core/widgets/vigi_mascot.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/checkin/domain/entities/monitoring_mode_entity.dart';
import '../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../features/checkin/presentation/bloc/checkin_event.dart';
import '../features/checkin/presentation/bloc/checkin_state.dart';
import '../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../features/family/presentation/bloc/family_bloc.dart';
import '../features/panic/presentation/bloc/panic_bloc.dart';
import '../injection/injection_container.dart';

import 'dart:async';
import 'package:home_widget/home_widget.dart';
import '../features/panic/presentation/bloc/panic_event.dart';

/// Raiz do app do idoso: cria os BLoCs, o roteador e trata os toques no widget da tela inicial.
class GuardiaoApp extends StatefulWidget {
  const GuardiaoApp({super.key, this.router});

  final GoRouter? router;

  @override
  State<GuardiaoApp> createState() => _GuardiaoAppState();
}

class _GuardiaoAppState extends State<GuardiaoApp> {
  late final AuthBloc _authBloc;
  late final CheckinBloc _checkinBloc;
  late final ContactsBloc _contactsBloc;
  late final PanicBloc _panicBloc;
  late final FamilyBloc _familyBloc;
  late final GoRouter _router;
  StreamSubscription<Uri?>? _widgetClickSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    // O status é carregado quando a sessão é confirmada (listener abaixo);
    // carregar antes disso gerava "Usuário não autenticado" na abertura.
    _checkinBloc = sl<CheckinBloc>();
    _contactsBloc = sl<ContactsBloc>();
    _panicBloc = sl<PanicBloc>();
    _familyBloc = sl<FamilyBloc>();
    _router = widget.router ?? buildRouter(_authBloc);

    // O status do monitoramento depende da sessão: sem isso, na primeira
    // instalação a tela inicial ficava sem o botão "Iniciar" após o login.
    _authSubscription = _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _checkinBloc.add(const LoadCheckinStatusRequested());
      }
    });

    _setupWidgetClickListener();
  }

  void _setupWidgetClickListener() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      _widgetClickSubscription = HomeWidget.widgetClicked.listen(
        _handleWidgetUri,
      );
    } catch (_) {}
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final uriString = uri.toString().toLowerCase();

    if (uri.host == 'confirmar_checkin' ||
        uriString.contains('confirmar_checkin')) {
      _checkinBloc.add(const ConfirmCheckinRequested());
    } else if (uri.host == 'iniciar_banho' ||
        uriString.contains('iniciar_banho')) {
      final state = _checkinBloc.state;
      final modes = state is CheckinIdle
          ? state.availableModes
          : <MonitoringModeEntity>[];
      final showerMode = modes
          .where(
            (m) =>
                m.iconKey == 'shower' || m.name.toLowerCase().contains('banho'),
          )
          .firstOrNull;
      final interval = showerMode?.defaultIntervalMinutes ?? 20;
      _checkinBloc.add(
        StartMonitoringRequested(
          modeId: showerMode?.id ?? 'mode-shower',
          intervalOverrideMinutes: interval,
        ),
      );
    } else if (uri.host == 'iniciar_sono' ||
        uriString.contains('iniciar_sono')) {
      final state = _checkinBloc.state;
      final modes = state is CheckinIdle
          ? state.availableModes
          : <MonitoringModeEntity>[];
      final sleepMode = modes
          .where(
            (m) =>
                m.iconKey == 'sleep' || m.name.toLowerCase().contains('sono'),
          )
          .firstOrNull;
      final interval = sleepMode?.defaultIntervalMinutes ?? 480;
      _checkinBloc.add(
        StartMonitoringRequested(
          modeId: sleepMode?.id ?? 'mode-sleep',
          intervalOverrideMinutes: interval,
        ),
      );
    } else if (uri.host == 'disparar_panico' ||
        uriString.contains('disparar_panico')) {
      _panicBloc.add(const PanicTriggered());
      // Mostra a tela de pânico para o usuário ver o status do envio.
      unawaited(_router.push('/panic'));
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _authSubscription?.cancel();
    _authBloc.close();
    _checkinBloc.close();
    _contactsBloc.close();
    _panicBloc.close();
    _familyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<CheckinBloc>.value(value: _checkinBloc),
        BlocProvider<ContactsBloc>.value(value: _contactsBloc),
        BlocProvider<PanicBloc>.value(value: _panicBloc),
        BlocProvider<FamilyBloc>.value(value: _familyBloc),
      ],
      child: MaterialApp.router(
        title: 'VIGI',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routerConfig: _router,
      ),
    );
  }
}

/// Tela inicial do idoso: estado do monitoramento, contagem regressiva, "Estou bem", modos rápidos (banho/sono) e acesso ao pânico.
class GuardiaoHomePage extends StatelessWidget {
  const GuardiaoHomePage({super.key});

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Sair com o monitoramento ativo deixaria o servidor esperando check-ins
  /// (alerta falso aos familiares) e o alarme local agendado.
  Future<void> _signOut(BuildContext context) async {
    final checkinBloc = context.read<CheckinBloc>();
    final authBloc = context.read<AuthBloc>();
    final current = checkinBloc.state;

    if (current is CheckinMonitoring || current is CheckinAlertActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'O monitoramento será pausado e seus contatos não serão mais '
            'avisados até você entrar novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Pausar e sair'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      checkinBloc.add(const StopMonitoringRequested());
      await checkinBloc.stream
          .firstWhere((s) => s is CheckinIdle || s is CheckinFailure)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => const CheckinInitial(),
          );
    }

    authBloc.add(const AuthSignOutRequested());
  }

  Widget _buildQuickModeButton({
    required BuildContext context,
    required String title,
    required String timeLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          side: const BorderSide(color: AppColors.petroleo, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        icon: Icon(icon, color: AppColors.petroleo, size: 20),
        label: Text(
          '$title\n($timeLabel)',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.petroleo,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('VIGI'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.petroleo,
            ),
            tooltip: 'Configurações de Rotina',
            onPressed: () => context.push('/monitoring-settings'),
          ),
          IconButton(
            icon: const Icon(
              Icons.people_alt_outlined,
              color: AppColors.petroleo,
            ),
            tooltip: 'Painel Familiar',
            onPressed: () => context.push('/family'),
          ),
          IconButton(
            icon: const Icon(
              Icons.contacts_outlined,
              color: AppColors.petroleo,
            ),
            tooltip: 'Contatos de Emergência',
            onPressed: () => context.push('/contacts'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.cinzaTexto),
            tooltip: 'Sair',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: BlocConsumer<CheckinBloc, CheckinState>(
            // A atualização do alerta (ex.: "contatos avisados") não pode
            // empilhar uma segunda tela de alerta.
            listenWhen: (previous, current) =>
                !(previous is CheckinAlertActive &&
                    current is CheckinAlertActive),
            listener: (context, state) {
              if (state is CheckinAlertActive) {
                // Redireciona para tela dedicada de alerta sonoro
                context.push('/checkin-alert');
              } else if (state is CheckinFailure) {
                final isContactError = state.message.toLowerCase().contains(
                  'contato',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.petroleo,
                    behavior: SnackBarBehavior.floating,
                    action: isContactError
                        ? SnackBarAction(
                            label: 'Cadastrar',
                            textColor: AppColors.ambar,
                            onPressed: () => context.push('/contacts'),
                          )
                        : null,
                  ),
                );
              }
            },
            builder: (context, state) {
              var vigiState = VigiState.normal;
              var progress = 0.0;
              var timeLabel = '--:--:--';
              var isMonitoring = false;
              String? modeTitle;
              var isTemporaryActive = false;

              if (state is CheckinMonitoring) {
                isMonitoring = true;
                vigiState = state.vigiState;
                progress = state.progress;
                timeLabel = _formatTime(state.remainingSeconds);
                final modeName = state.activeMode?.name ?? 'Rotina';
                final modeMin = state.totalSeconds ~/ 60;
                modeTitle = 'Monitorando: $modeName — $modeMin min';

                final actKey = state.activeMode?.iconKey;
                final actName = state.activeMode?.name.toLowerCase() ?? '';
                isTemporaryActive =
                    actKey == 'shower' ||
                    actName.contains('banho') ||
                    actKey == 'sleep' ||
                    actName.contains('sono');
              } else if (state is CheckinAlertActive) {
                vigiState = VigiState.alerta;
                progress = 1.0;
                timeLabel = 'EXPIRADO';
                modeTitle = 'Alerta de Check-in Expirado';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: VigiMascot(
                      state: vigiState,
                      size: 130,
                      animate: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMonitoring
                        ? (modeTitle ?? 'Monitoramento Ativo')
                        : 'Você está protegido pelo VIGI',
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(color: AppColors.petroleo),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMonitoring
                        ? (isTemporaryActive
                              ? 'Ao confirmar, você retornará automaticamente à Rotina padrão'
                              : 'Confirme sua presença antes do prazo zerar')
                        : 'Toque abaixo para iniciar seu monitoramento diário',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: StatusRing(
                      progress: progress,
                      state: vigiState,
                      size: 170,
                      strokeWidth: 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeLabel,
                            style: AppTypography.h2.copyWith(
                              color: vigiState == VigiState.alerta
                                  ? AppColors.panico
                                  : AppColors.petroleo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMonitoring ? 'Próximo check-in' : 'Timer inativo',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.cinzaTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isMonitoring) ...[
                    Builder(
                      builder: (context) {
                        final act = state is CheckinMonitoring
                            ? state.activeMode
                            : null;
                        final isShower =
                            act?.iconKey == 'shower' ||
                            (act?.name.toLowerCase().contains('banho') ??
                                false);
                        final isSleep =
                            act?.iconKey == 'sleep' ||
                            (act?.name.toLowerCase().contains('sono') ?? false);

                        String confirmText = 'Estou Bem';
                        if (isShower) {
                          confirmText = 'Terminei o Banho';
                        } else if (isSleep) {
                          confirmText = 'Acordei, Estou Bem';
                        }

                        return AppPrimaryButton(
                          text: confirmText,
                          icon: Icons.check_circle_outline,
                          onPressed: () {
                            context.read<CheckinBloc>().add(
                              const ConfirmCheckinRequested(),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      text: 'Pausar Monitoramento',
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context.read<CheckinBloc>().add(
                          const StopMonitoringRequested(),
                        );
                      },
                    ),
                  ] else if (state is CheckinIdle) ...[
                    AppPrimaryButton(
                      text:
                          'Iniciar ${state.selectedMode?.name ?? "Rotina"} (${state.intervalMinutes} min)',
                      icon: Icons.play_arrow,
                      onPressed: () {
                        context.read<CheckinBloc>().add(
                          StartMonitoringRequested(
                            modeId:
                                state.selectedMode?.id ??
                                'system-default-routine',
                            intervalOverrideMinutes: state.intervalMinutes,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final modes = state.availableModes;
                        final showerMode =
                            modes
                                .where(
                                  (m) =>
                                      m.iconKey == 'shower' ||
                                      m.name.toLowerCase().contains('banho'),
                                )
                                .firstOrNull ??
                            const MonitoringModeEntity(
                              id: 'system-default-shower',
                              name: 'Banho',
                              iconKey: 'shower',
                              defaultIntervalMinutes: 20,
                              isSystemDefault: true,
                            );

                        final sleepMode =
                            modes
                                .where(
                                  (m) =>
                                      m.iconKey == 'sleep' ||
                                      m.name.toLowerCase().contains('sono'),
                                )
                                .firstOrNull ??
                            const MonitoringModeEntity(
                              id: 'system-default-sleep',
                              name: 'Sono',
                              iconKey: 'sleep',
                              defaultIntervalMinutes: 480,
                              isSystemDefault: true,
                            );

                        final showerTimeStr =
                            '${showerMode.defaultIntervalMinutes} min';
                        final sleepTimeStr =
                            sleepMode.defaultIntervalMinutes % 60 == 0
                            ? '${sleepMode.defaultIntervalMinutes ~/ 60}h'
                            : '${sleepMode.defaultIntervalMinutes} min';

                        return Row(
                          children: [
                            _buildQuickModeButton(
                              context: context,
                              title: 'Vou tomar banho',
                              timeLabel: showerTimeStr,
                              icon: Icons.shower,
                              onTap: () {
                                context.read<CheckinBloc>().add(
                                  StartMonitoringRequested(
                                    modeId: showerMode.id,
                                    intervalOverrideMinutes:
                                        showerMode.defaultIntervalMinutes,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildQuickModeButton(
                              context: context,
                              title: 'Vou dormir',
                              timeLabel: sleepTimeStr,
                              icon: Icons.bedtime,
                              onTap: () {
                                context.read<CheckinBloc>().add(
                                  StartMonitoringRequested(
                                    modeId: sleepMode.id,
                                    intervalOverrideMinutes:
                                        sleepMode.defaultIntervalMinutes,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ] else if (state is CheckinLoading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.petroleo,
                        ),
                      ),
                    ),
                  ] else ...[
                    AppPrimaryButton(
                      text: 'Iniciar Monitoramento (60 min)',
                      icon: Icons.play_arrow,
                      onPressed: () {
                        context.read<CheckinBloc>().add(
                          const StartMonitoringRequested(
                            modeId: 'system-default-routine',
                            intervalOverrideMinutes: 60,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickModeButton(
                          context: context,
                          title: 'Vou tomar banho',
                          timeLabel: '20 min',
                          icon: Icons.shower,
                          onTap: () {
                            context.read<CheckinBloc>().add(
                              const StartMonitoringRequested(
                                modeId: 'system-default-shower',
                                intervalOverrideMinutes: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildQuickModeButton(
                          context: context,
                          title: 'Vou dormir',
                          timeLabel: '8h',
                          icon: Icons.bedtime,
                          onTap: () {
                            context.read<CheckinBloc>().add(
                              const StartMonitoringRequested(
                                modeId: 'system-default-sleep',
                                intervalOverrideMinutes: 480,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    text: 'Abrir Botão de Pânico',
                    variant: AppButtonVariant.danger,
                    icon: Icons.emergency,
                    onPressed: () => context.push('/panic'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
