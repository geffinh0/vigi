import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../../domain/entities/family_link_entity.dart';
import '../../domain/entities/monitoring_snapshot_entity.dart';
import '../../domain/entities/wellbeing_status.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/usecases/get_family_links_usecase.dart';
import '../../domain/usecases/request_family_link_usecase.dart';

/// Uma pessoa acompanhada, pronta para exibição no painel da família.
class MonitoredPersonView extends Equatable {
  const MonitoredPersonView({
    required this.link,
    required this.status,
    this.modeName,
    this.recentEvents = const [],
  });

  final FamilyLinkEntity link;
  final WellbeingStatus status;
  final String? modeName;
  final List<PanicAlertEntity> recentEvents;

  String get name {
    final n = link.monitoredUserName?.trim();
    return (n == null || n.isEmpty) ? 'Pessoa acompanhada' : n;
  }

  @override
  List<Object?> get props => [link, status, modeName, recentEvents];
}

class FamilyDashboardState extends Equatable {
  const FamilyDashboardState({
    this.loading = true,
    this.people = const [],
    this.pendingRequests = const [],
    this.errorMessage,
    this.infoMessage,
    this.alertSignal = 0,
    this.alertText,
    this.now,
  });

  final bool loading;
  final List<MonitoredPersonView> people;

  /// Pedidos feitos por esta conta que ainda aguardam autorização.
  final List<FamilyLinkEntity> pendingRequests;
  final String? errorMessage;
  final String? infoMessage;

  /// Incrementado a cada emergência NOVA (dispara som/notificação na tela).
  final int alertSignal;
  final String? alertText;
  final DateTime? now;

  bool get hasEmergency =>
      people.any((p) => p.status.level == WellbeingLevel.emergency);

  FamilyDashboardState copyWith({
    bool? loading,
    List<MonitoredPersonView>? people,
    List<FamilyLinkEntity>? pendingRequests,
    String? errorMessage,
    String? infoMessage,
    int? alertSignal,
    String? alertText,
    DateTime? now,
  }) {
    return FamilyDashboardState(
      loading: loading ?? this.loading,
      people: people ?? this.people,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      alertSignal: alertSignal ?? this.alertSignal,
      alertText: alertText ?? this.alertText,
      now: now ?? this.now,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    people,
    pendingRequests,
    errorMessage,
    infoMessage,
    alertSignal,
    alertText,
    now,
  ];
}

/// Painel do familiar: acompanha em tempo real (Supabase Realtime) o
/// bem-estar das pessoas que autorizaram o vínculo.
class FamilyDashboardCubit extends Cubit<FamilyDashboardState> {
  FamilyDashboardCubit({
    required this.repository,
    required this.getFamilyLinksUseCase,
    required this.requestFamilyLinkUseCase,
    required this.currentUserId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const FamilyDashboardState());

  final FamilyRepository repository;
  final GetFamilyLinksUseCase getFamilyLinksUseCase;
  final RequestFamilyLinkUseCase requestFamilyLinkUseCase;
  final String? Function() currentUserId;
  final DateTime Function() _now;

  List<FamilyLinkEntity> _followed = [];
  Map<String, String> _modeNames = {};
  final Map<String, MonitoringSnapshotEntity?> _snapshots = {};
  final Map<String, List<PanicAlertEntity>> _events = {};
  final Map<String, List<StreamSubscription<dynamic>>> _personSubs = {};
  final Set<String> _knownAlertIds = {};
  final Set<String> _eventsLoaded = {};
  StreamSubscription<void>? _linksSub;
  Timer? _clockTimer;
  Timer? _authRetryTimer;
  int _authRetries = 0;

  Future<void> start() async {
    _modeNames = await repository.getModeNames();
    await _reloadLinks();

    _linksSub ??= repository
        .watchLinksChanges()
        .skip(1)
        .listen(
          (_) => _reloadLinks(),
          onError: (_) {},
        );
    // Atualiza "há X min" e detecta prazos vencidos mesmo sem novos eventos.
    _clockTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _recompute(),
    );
  }

  Future<void> requestLink(String code) async {
    final result = await requestFamilyLinkUseCase(code);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (name) => emit(
        state.copyWith(
          infoMessage:
              'Pedido enviado! ${name.isEmpty ? 'A pessoa' : name} precisa '
              'tocar em "Permitir" no app VIGI do celular.',
        ),
      ),
    );
    await _reloadLinks();
  }

  Future<void> _reloadLinks() async {
    final result = await getFamilyLinksUseCase(const NoParams());
    if (isClosed) return;
    final me = currentUserId();

    result.fold(
      (failure) {
        // Sessão ainda sendo renovada: tenta de novo em silêncio.
        if (failure is AuthFailure && _authRetries < 5) {
          _authRetries++;
          _authRetryTimer?.cancel();
          _authRetryTimer = Timer(const Duration(seconds: 2), _reloadLinks);
          return;
        }
        emit(state.copyWith(loading: false, errorMessage: failure.message));
      },
      (links) {
        _authRetries = 0;
        final mine = links.where((l) => l.viewerUserId == me).toList();
        _followed = mine.where((l) => l.isAccepted).toList();

        final followedIds = _followed.map((l) => l.monitoredUserId).toSet();
        for (final id in _personSubs.keys.toList()) {
          if (!followedIds.contains(id)) _unwatch(id);
        }
        for (final id in followedIds) {
          if (!_personSubs.containsKey(id)) _watch(id);
        }

        emit(
          state.copyWith(
            loading: false,
            pendingRequests: mine.where((l) => l.isPending).toList(),
          ),
        );
        _recompute();
      },
    );
  }

  void _watch(String userId) {
    _personSubs[userId] = [
      repository.watchMonitoringSnapshot(userId).listen((snapshot) {
        _snapshots[userId] = snapshot;
        _recompute();
      }, onError: (_) {}),
      repository.watchMonitoredEvents(userId).listen((events) {
        _events[userId] = events;
        _detectNewAlerts(userId, events);
        _recompute();
      }, onError: (_) {}),
    ];
  }

  void _unwatch(String userId) {
    for (final sub
        in _personSubs.remove(userId) ??
            const <StreamSubscription<dynamic>>[]) {
      unawaited(sub.cancel());
    }
    _snapshots.remove(userId);
    _events.remove(userId);
    _eventsLoaded.remove(userId);
  }

  /// Só sinaliza alertas que chegaram com o painel aberto; os antigos
  /// aparecem no cartão, mas sem tocar o som novamente.
  void _detectNewAlerts(String userId, List<PanicAlertEntity> events) {
    final alerts = events.where(
      (e) => e.eventType == 'panic' || e.eventType == 'alert_triggered',
    );
    final firstLoad = _eventsLoaded.add(userId);
    final fresh = alerts.where((e) => _knownAlertIds.add(e.id)).toList();
    if (firstLoad || fresh.isEmpty || isClosed) return;

    final link = _followed
        .where((l) => l.monitoredUserId == userId)
        .firstOrNull;
    final name = link?.monitoredUserName?.trim().isNotEmpty ?? false
        ? link!.monitoredUserName!.trim()
        : 'A pessoa que você acompanha';
    final isPanic = fresh.first.eventType == 'panic';
    emit(
      state.copyWith(
        alertSignal: state.alertSignal + 1,
        alertText: isPanic
            ? '$name acionou o botão de pânico!'
            : '$name não respondeu ao check-in!',
      ),
    );
  }

  void _recompute() {
    if (isClosed) return;
    final now = _now();
    final people = _followed.map((link) {
      final id = link.monitoredUserId;
      final snapshot = _snapshots[id];
      final events = _events[id] ?? const <PanicAlertEntity>[];
      return MonitoredPersonView(
        link: link,
        status: WellbeingStatus.evaluate(
          snapshot: snapshot,
          events: events,
          now: now,
        ),
        modeName: snapshot?.activeModeId == null
            ? null
            : _modeNames[snapshot!.activeModeId],
        recentEvents: events.take(5).toList(),
      );
    }).toList();

    emit(state.copyWith(people: people, now: now));
  }

  @override
  Future<void> close() async {
    _clockTimer?.cancel();
    _authRetryTimer?.cancel();
    await _linksSub?.cancel();
    _personSubs.keys.toList().forEach(_unwatch);
    return super.close();
  }
}
