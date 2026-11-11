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
enum HealthIssue {
  /// Nenhuma pessoa cadastrada para ser avisada.
  noContacts,

  /// Notificações bloqueadas: o Vigi não consegue chamar.
  notificationsBlocked,

  /// Sem permissão de SMS: o Vigi não consegue avisar ninguém sozinho.
  smsDenied,

  /// Localização negada: o pedido de ajuda vai sem o "onde".
  locationDenied,

  /// Economia de bateria ativa: o Android pode fechar o Vigi.
  batteryOptimized,

  /// Sem internet: o aviso sai só por SMS.
  offline,
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

  /// Avisa quando a conexão cai ou volta.
  Stream<void> get changes;
}

/// Implementação com os plugins já usados pelo app e um canal nativo
/// (`vigi/system`) para a economia de bateria.
class SystemHealthServiceImpl implements SystemHealthService {
  SystemHealthServiceImpl({
    required this.notificationService,
    this.networkInfo,
    this.emergencyDispatcher,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('vigi/system');

  final NotificationService notificationService;
  final NetworkInfo? networkInfo;
  final EmergencyDispatcher? emergencyDispatcher;
  final MethodChannel _channel;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<void> get changes =>
      networkInfo?.onConnectivityChanged.map((_) {}) ?? const Stream.empty();

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
      try {
        final ignoring = await _channel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations',
        );
        if (ignoring == false) issues.add(HealthIssue.batteryOptimized);
      } catch (_) {}
    }

    try {
      if (networkInfo != null && !await networkInfo!.isConnected) {
        issues.add(HealthIssue.offline);
      }
    } catch (_) {}

    return issues;
  }

  @override
  Future<bool> fix(HealthIssue issue) async {
    try {
      switch (issue) {
        case HealthIssue.notificationsBlocked:
          if (await notificationService.requestPermission()) return true;
          await Geolocator.openAppSettings();
          return false;
        case HealthIssue.smsDenied:
          await emergencyDispatcher?.ensurePermissions();
          return await emergencyDispatcher?.hasSmsPermission() ?? false;
        case HealthIssue.locationDenied:
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            return true;
          }
          await Geolocator.openAppSettings();
          return false;
        case HealthIssue.batteryOptimized:
          await _channel.invokeMethod<bool>('openBatterySettings');
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
