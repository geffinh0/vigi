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
import '../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../features/checkin/presentation/bloc/checkin_event.dart';
import '../features/checkin/presentation/bloc/checkin_state.dart';
import '../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../features/family/presentation/bloc/family_bloc.dart';
import '../features/panic/presentation/bloc/panic_bloc.dart';
import '../injection/injection_container.dart';

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

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _checkinBloc = sl<CheckinBloc>()..add(const LoadCheckinStatusRequested());
    _contactsBloc = sl<ContactsBloc>();
    _panicBloc = sl<PanicBloc>();
    _familyBloc = sl<FamilyBloc>();
    _router = widget.router ?? buildRouter(_authBloc);
  }

  @override
  void dispose() {
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
        title: 'Guardião',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routerConfig: _router,
      ),
    );
  }
}

class GuardiaoHomePage extends StatelessWidget {
  const GuardiaoHomePage({super.key});

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('Guardião'),
        actions: [
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
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: BlocBuilder<CheckinBloc, CheckinState>(
            builder: (context, state) {
              var vigiState = VigiState.normal;
              var progress = 0.0;
              var timeLabel = '--:--:--';
              var isMonitoring = false;

              if (state is CheckinMonitoring) {
                isMonitoring = true;
                vigiState = state.vigiState;
                progress = state.progress;
                timeLabel = _formatTime(state.remainingSeconds);
              } else if (state is CheckinAlertActive) {
                vigiState = VigiState.alerta;
                progress = 1.0;
                timeLabel = 'EXPIRADO';
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
                        ? 'Monitoramento Ativo'
                        : 'Você está protegido pelo Vigi',
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(color: AppColors.petroleo),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMonitoring
                        ? 'Confirme sua presença antes do prazo zerar'
                        : 'Inicie sua rotina para ativar a verificação periódica',
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
                    AppPrimaryButton(
                      text: 'Estou Bem (Confirmar Check-in)',
                      icon: Icons.check_circle_outline,
                      onPressed: () {
                        context.read<CheckinBloc>().add(
                          const ConfirmCheckinRequested(),
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
                  ] else ...[
                    AppPrimaryButton(
                      text: 'Iniciar Monitoramento (60 min)',
                      icon: Icons.play_arrow,
                      onPressed: () {
                        context.read<CheckinBloc>().add(
                          const StartMonitoringRequested(intervalMinutes: 60),
                        );
                      },
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
