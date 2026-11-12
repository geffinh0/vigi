import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../network/network_info.dart';
import 'emergency_dispatcher.dart';
import 'notification_service.dart';

/// O que pode impedir o Vigi de proteger a pessoa.
///
/// Princípio "falhar alto": se algo compromete a proteção, isso aparece no
/// topo da tela inicial, em linguagem clara, com o botão que resolve. Um
/// sistema de segurança que falha em silêncio é pior que nenhum.
///
/// A ordem dos valores é a ordem de gravidade.
enum HealthIssue {
  /// Nenhuma pessoa cadastrada para ser avisada.
  noContacts,

  /// Notificações bloqueadas: o Vigi não consegue chamar.
  notificationsBlocked,

  /// Sem permissão de SMS: o Vigi não consegue avisar ninguém sozinho.
  smsDenied,

  /// Alarmes exatos desligados: a chamada pode atrasar.
  exactAlarmsDenied,

  /// Alarme em tela cheia desligado (Android 14 ou mais novo).
  fullScreenDenied,

  /// Localização negada: o pedido de ajuda vai sem o "onde".
  locationDenied,

  /// Economia de bateria ativa: o Android pode fechar o Vigi.
  batteryOptimized,

  /// Sem internet: o aviso sai só por SMS.
  offline
  ;

  /// É uma permissão ou ajuste do aparelho que a pessoa concede (e que a
  /// tela "Permissões" lista).
  bool get isPermission =>
      this != HealthIssue.noContacts && this != HealthIssue.offline;
}

/// Verifica as condições do aparelho de que o Vigi depende e abre a tela
/// certa para corrigir cada uma.
abstract class SystemHealthService {
  /// Problemas encontrados agora, do mais grave para o menos grave.
  /// Não inclui [HealthIssue.noContacts], que depende dos dados da conta.
  Future<List<HealthIssue>> check();

  /// Leva a pessoa direto à correção de [issue]. Devolve `true` se o problema
  /// foi resolvido na hora.
  Future<bool> fix(HealthIssue issue);

  /// Permissões e ajustes que fazem sentido neste aparelho, na ordem em que
  /// a tela "Permissões" os mostra.
  List<HealthIssue> get permissionKinds;

  /// Avisa quando a conexão cai ou volta.
  Stream<void> get changes;
}

/// Implementação com os plugins já usados pelo app e um canal nativo
/// (`vigi/system`) para a economia de bateria e o alarme em tela cheia.
class SystemHealthServiceImpl implements SystemHealthService {
  SystemHealthServiceImpl({
    required this.notificationService,
    this.networkInfo,
    this.emergencyDispatcher,
    MethodChannel? channel,
    bool? isAndroid,
  }) : _channel = channel ?? const MethodChannel('vigi/system'),
       _isAndroid =
           isAndroid ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final NotificationService notificationService;
  final NetworkInfo? networkInfo;
  final EmergencyDispatcher? emergencyDispatcher;
  final MethodChannel _channel;
  final bool _isAndroid;

  @override
  List<HealthIssue> get permissionKinds => [
    HealthIssue.notificationsBlocked,
    if (_isAndroid && emergencyDispatcher != null) HealthIssue.smsDenied,
    HealthIssue.locationDenied,
    if (_isAndroid) ...[
      HealthIssue.exactAlarmsDenied,
      HealthIssue.fullScreenDenied,
      HealthIssue.batteryOptimized,
    ],
  ];

  @override
  Stream<void> get changes =>
      networkInfo?.onConnectivityChanged.map((_) {}) ?? const Stream.empty();

  Future<bool?> _native(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method);
    } catch (_) {
      // Sem o canal nativo (versão antiga, outra plataforma): sem resposta.
      return null;
    }
  }

  @override
  Future<List<HealthIssue>> check() async {
    final issues = <HealthIssue>[];

    if (!await notificationService.areNotificationsEnabled()) {
      issues.add(HealthIssue.notificationsBlocked);
    }

    if (_isAndroid && emergencyDispatcher != null) {
      if (!await emergencyDispatcher!.hasSmsPermission()) {
        issues.add(HealthIssue.smsDenied);
      }
    }

    if (_isAndroid) {
      if (!await notificationService.canScheduleExactAlarms()) {
        issues.add(HealthIssue.exactAlarmsDenied);
      }
      if (await _native('canUseFullScreenIntent') == false) {
        issues.add(HealthIssue.fullScreenDenied);
      }
    }

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        issues.add(HealthIssue.locationDenied);
      }
    } catch (_) {
      // Plataforma sem localização: não é algo que a pessoa consiga corrigir.
    }

    if (_isAndroid) {
      if (await _native('isIgnoringBatteryOptimizations') == false) {
        issues.add(HealthIssue.batteryOptimized);
      }
    }

    try {
      if (networkInfo != null && !await networkInfo!.isConnected) {
        issues.add(HealthIssue.offline);
      }
    } catch (_) {}

    return issues;
  }

  Future<void> _openAppSettings() async {
    if (await _native('openAppSettings') ?? false) return;
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  @override
  Future<bool> fix(HealthIssue issue) async {
    try {
      switch (issue) {
        case HealthIssue.notificationsBlocked:
          if (await notificationService.requestPermission()) return true;
          // Negada em definitivo: só as configurações do app resolvem.
          await _openAppSettings();
          return false;
        case HealthIssue.smsDenied:
          await emergencyDispatcher?.requestSmsPermission();
          return await emergencyDispatcher?.hasSmsPermission() ?? false;
        case HealthIssue.exactAlarmsDenied:
          return notificationService.requestExactAlarms();
        case HealthIssue.fullScreenDenied:
          await _native('openFullScreenIntentSettings');
          return false;
        case HealthIssue.locationDenied:
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            return true;
          }
          if (permission == LocationPermission.deniedForever) {
            await _openAppSettings();
          }
          return false;
        case HealthIssue.batteryOptimized:
          await _native('openBatterySettings');
          return false;
        case HealthIssue.offline:
        case HealthIssue.noContacts:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
