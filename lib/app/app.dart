import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import '../core/router/app_router.dart';
import '../core/services/notification_service.dart';
import '../core/services/system_health_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/vigi_palette.dart';
import '../core/theme/vigi_tokens.dart';
import '../core/widgets/vigi_dialogs.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/checkin/domain/entities/monitoring_mode_entity.dart';
import '../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../features/checkin/presentation/bloc/checkin_event.dart';
import '../features/checkin/presentation/bloc/checkin_state.dart';
import '../features/checkin/presentation/pages/modes_tab.dart';
import '../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../features/contacts/presentation/bloc/contacts_event.dart';
import '../features/family/presentation/bloc/family_bloc.dart';
import '../features/panic/presentation/bloc/panic_bloc.dart';
import '../features/panic/presentation/widgets/panic_button.dart';
import '../injection/injection_container.dart';
import 'config/app_config.dart';
import 'home/home_tab.dart';
import 'home/people_tab.dart';
import 'permissions_page.dart';
import 'system_health_cubit.dart';

/// Ação pedida de fora do app (widget ou notificação) que espera a vigília
/// carregar para ser aplicada.
enum _PendingAction { confirm, snooze }

/// Raiz do app da pessoa acompanhada: cria os BLoCs, o roteador e trata os
/// toques no widget da tela inicial e nas ações das notificações.
class VigiApp extends StatefulWidget {
  const VigiApp({super.key, this.router});

  final GoRouter? router;

  @override
  State<VigiApp> createState() => _VigiAppState();
}

class _VigiAppState extends State<VigiApp> {
  late final AuthBloc _authBloc;
  late final CheckinBloc _checkinBloc;
  late final ContactsBloc _contactsBloc;
  late final PanicBloc _panicBloc;
  late final FamilyBloc _familyBloc;
  late final SystemHealthCubit _healthCubit;
  late final GoRouter _router;
  StreamSubscription<Uri?>? _widgetClickSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<CheckinState>? _checkinSubscription;
  StreamSubscription<NotificationAction>? _notificationSubscription;
  _PendingAction? _pendingAction;

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
    _healthCubit = SystemHealthCubit(
      sl.isRegistered<SystemHealthService>() ? sl<SystemHealthService>() : null,
    );
    _router = widget.router ?? buildRouter(_authBloc);

    // O status do monitoramento e os contatos dependem da sessão.
    _authSubscription = _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _checkinBloc.add(const LoadCheckinStatusRequested());
        _contactsBloc.add(const LoadContactsRequested());
        unawaited(_healthCubit.refresh());
      }
    });

    // Ações que chegaram antes de a vigília carregar são aplicadas assim
    // que houver um prazo para confirmar.
    _checkinSubscription = _checkinBloc.stream.listen(_applyPendingAction);

    _setupWidgetClickListener();
    _setupNotificationActions();
  }

  void _setupWidgetClickListener() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      _widgetClickSubscription = HomeWidget.widgetClicked.listen(
        _handleWidgetUri,
      );
    } catch (_) {}
  }

  void _setupNotificationActions() {
    if (!sl.isRegistered<NotificationService>()) return;
    final notifications = sl<NotificationService>();
    _notificationSubscription = notifications.actions.listen(
      _handleNotificationAction,
    );
    unawaited(
      notifications.takeLaunchAction().then((action) {
        if (action != null) _handleNotificationAction(action);
      }),
    );
  }

  void _handleNotificationAction(NotificationAction action) {
    _requestAction(switch (action) {
      NotificationAction.confirm => _PendingAction.confirm,
      NotificationAction.snooze => _PendingAction.snooze,
    });
  }

  /// Confirma (ou adia) agora, se a vigília já carregou; senão guarda o
  /// pedido para quando carregar.
  void _requestAction(_PendingAction action) {
    final state = _checkinBloc.state;
    if (state is CheckinInitial || state is CheckinLoading) {
      _pendingAction = action;
      return;
    }
    _dispatchAction(action);
  }

  void _dispatchAction(_PendingAction action) {
    _checkinBloc.add(switch (action) {
      _PendingAction.confirm => const ConfirmCheckinRequested(),
      _PendingAction.snooze => const SnoozeCheckinRequested(),
    });
  }

  void _applyPendingAction(CheckinState state) {
    final action = _pendingAction;
    if (action == null) return;
    if (state is CheckinInitial || state is CheckinLoading) return;
    _pendingAction = null;
    if (state is CheckinMonitoring ||
        state is CheckinCalling ||
        state is CheckinAlertActive) {
      _dispatchAction(action);
    }
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final uriString = uri.toString().toLowerCase();
    bool matches(String action) =>
        uri.host == action || uriString.contains(action);

    if (matches('confirmar_checkin')) {
      _requestAction(_PendingAction.confirm);
    } else if (matches('iniciar_banho')) {
      _startTemporaryMode((m) => m.isShower, 'mode-shower', 20);
    } else if (matches('iniciar_sono')) {
      _startTemporaryMode((m) => m.isSleep, 'mode-sleep', 480);
    } else if (matches('pedir_ajuda') || matches('disparar_panico')) {
      // O pedido de ajuda nunca sai por um toque só: o widget apenas abre
      // a tela, onde a pessoa segura o botão por 3 segundos.
      unawaited(_router.push('/panic'));
    }
  }

  void _startTemporaryMode(
    bool Function(MonitoringModeEntity) test,
    String fallbackId,
    int fallbackMinutes,
  ) {
    final state = _checkinBloc.state;
    final modes = switch (state) {
      CheckinIdle(:final availableModes) => availableModes,
      CheckinMonitoring(:final availableModes) => availableModes,
      _ => const <MonitoringModeEntity>[],
    };
    final mode = modes.where(test).firstOrNull;
    _checkinBloc.add(
      StartMonitoringRequested(
        modeId: mode?.id ?? fallbackId,
        intervalOverrideMinutes:
            mode?.defaultIntervalMinutes ?? fallbackMinutes,
      ),
    );
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _authSubscription?.cancel();
    _checkinSubscription?.cancel();
    _notificationSubscription?.cancel();
    _authBloc.close();
    _checkinBloc.close();
    _contactsBloc.close();
    _panicBloc.close();
    _familyBloc.close();
    _healthCubit.close();
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
        BlocProvider<SystemHealthCubit>.value(value: _healthCubit),
      ],
      child: BlocSelector<CheckinBloc, CheckinState, bool>(
        // O modo Sono ativa o tema noturno, independentemente do sistema.
        selector: (state) => state is CheckinMonitoring && state.isSleep,
        builder: (context, sleeping) => MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          darkTheme: vigiNightTheme,
          // Fora do modo Sono, o tema noturno segue a configuração do sistema.
          themeMode: sleeping ? ThemeMode.dark : ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }
}

/// Tela inicial da pessoa acompanhada.
///
/// Não há menu hambúrguer: Início, Modos e Pessoas ficam em uma barra
/// inferior com três itens, com ícone e texto. Acima dela, em lugar fixo e
/// sempre visível, o botão "Pedir ajuda".
class VigiHomePage extends StatefulWidget {
  const VigiHomePage({super.key, this.now});

  /// Relógio injetável para os testes (a saudação muda com a hora).
  final DateTime Function()? now;

  @override
  State<VigiHomePage> createState() => _VigiHomePageState();
}

class _VigiHomePageState extends State<VigiHomePage>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<SystemHealthCubit>().refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<CheckinBloc>().state;
      if (state is CheckinCalling || state is CheckinAlertActive) {
        // Abrindo o app já em chamada ou alerta, vai direto para a tela cheia.
        unawaited(context.push('/checkin-alert'));
      } else if (PermissionsIntro.pending &&
          context.read<SystemHealthCubit>().permissionKinds.isNotEmpty) {
        // Primeira vez: explica as permissões antes de o sistema perguntar.
        unawaited(context.push('/permissions'));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltando das configurações do sistema, a faixa de saúde se atualiza.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<SystemHealthCubit>().refresh());
    }
  }

  /// Sair com o monitoramento ativo deixaria o servidor esperando check-ins
  /// (alerta falso aos familiares) e a chamada agendada.
  Future<void> _signOut() async {
    final checkinBloc = context.read<CheckinBloc>();
    final authBloc = context.read<AuthBloc>();
    final current = checkinBloc.state;
    final watching =
        current is CheckinMonitoring ||
        current is CheckinCalling ||
        current is CheckinAlertActive;

    final confirmed = await showVigiConfirm(
      context,
      title: 'Sair da conta?',
      message: watching
          ? 'A vigília será pausada e ninguém será avisado até você entrar '
                'de novo.'
          : 'Você precisará do e-mail e da senha para entrar de novo.',
      confirmLabel: watching ? 'Pausar e sair' : 'Sair da conta',
    );
    if (!confirmed) return;

    if (watching) {
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

  void _onCheckinState(BuildContext context, CheckinState state) {
    if (state is CheckinCalling || state is CheckinAlertActive) {
      unawaited(context.push('/checkin-alert'));
    } else if (state is CheckinFailure) {
      final aboutContacts = state.message.toLowerCase().contains('contato');
      showVigiMessage(
        context,
        aboutContacts
            ? 'O Vigi só começa a vigiar depois que você escolher pelo '
                  'menos uma pessoa.'
            : state.message,
        actionLabel: aboutContacts ? 'Escolher' : null,
        onAction: aboutContacts ? () => setState(() => _tab = 2) : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return BlocListener<CheckinBloc, CheckinState>(
      // Entrar na chamada abre a tela cheia uma vez; a passagem para a
      // última chamada e para o alerta acontece dentro dela.
      listenWhen: (previous, current) {
        final wasUrgent =
            previous is CheckinCalling || previous is CheckinAlertActive;
        final isUrgent =
            current is CheckinCalling || current is CheckinAlertActive;
        return (isUrgent && !wasUrgent) || current is CheckinFailure;
      },
      listener: _onCheckinState,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              HomeTab(
                now: widget.now,
                onOpenModes: () => setState(() => _tab = 1),
                onOpenPeople: () => setState(() => _tab = 2),
              ),
              const ModesTab(),
              PeopleTab(onSignOut: _signOut),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, color: palette.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VigiSpace.screen,
                  VigiSpace.x3,
                  VigiSpace.screen,
                  VigiSpace.x1,
                ),
                child: PanicButton(
                  style: PanicButtonStyle.footer,
                  onTap: () => context.push('/panic'),
                  onPanicTriggered: () => context.push('/panic'),
                  onReleasedEarly: () => showVigiMessage(
                    context,
                    PanicButton.releasedEarlyMessage,
                  ),
                ),
              ),
              NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) => setState(() => _tab = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.schedule_outlined),
                    selectedIcon: Icon(Icons.schedule_rounded),
                    label: 'Modos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: 'Pessoas',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
