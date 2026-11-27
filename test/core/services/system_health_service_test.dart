import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/network/network_info.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/services/notification_service.dart';
import 'package:guardiao/core/services/system_health_service.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockEmergencyDispatcher extends Mock implements EmergencyDispatcher {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('vigi/system');
  late MockNotificationService notifications;
  late MockEmergencyDispatcher dispatcher;
  late MockNetworkInfo network;
  late Map<String, Object?> native;
  late List<String> nativeCalls;

  SystemHealthServiceImpl build({bool isAndroid = true}) =>
      SystemHealthServiceImpl(
        notificationService: notifications,
        networkInfo: network,
        emergencyDispatcher: dispatcher,
        isAndroid: isAndroid,
      );

  setUp(() {
    notifications = MockNotificationService();
    dispatcher = MockEmergencyDispatcher();
    network = MockNetworkInfo();
    native = {
      'isIgnoringBatteryOptimizations': true,
      'canUseFullScreenIntent': true,
      'openBatterySettings': true,
      'openFullScreenIntentSettings': true,
      'openAppSettings': true,
    };
    nativeCalls = [];

    when(
      () => notifications.areNotificationsEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => notifications.canScheduleExactAlarms(),
    ).thenAnswer((_) async => true);
    when(() => notifications.requestPermission()).thenAnswer((_) async => true);
    when(
      () => notifications.requestExactAlarms(),
    ).thenAnswer((_) async => true);
    when(() => dispatcher.hasSmsPermission()).thenAnswer((_) async => true);
    when(() => dispatcher.requestSmsPermission()).thenAnswer((_) async {});
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(
      () => network.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          nativeCalls.add(call.method);
          return native[call.method];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('check', () {
    test(
      'acusa o que estiver faltando, do mais grave ao menos grave',
      () async {
        when(
          () => notifications.areNotificationsEnabled(),
        ).thenAnswer((_) async => false);
        when(
          () => dispatcher.hasSmsPermission(),
        ).thenAnswer((_) async => false);
        when(
          () => notifications.canScheduleExactAlarms(),
        ).thenAnswer((_) async => false);
        native['canUseFullScreenIntent'] = false;
        native['isIgnoringBatteryOptimizations'] = false;
        when(() => network.isConnected).thenAnswer((_) async => false);

        final issues = await build().check();

        // A localização (plugin ausente nos testes) não entra na conta.
        expect(issues, [
          HealthIssue.notificationsBlocked,
          HealthIssue.smsDenied,
          HealthIssue.exactAlarmsDenied,
          HealthIssue.fullScreenDenied,
          HealthIssue.batteryOptimized,
          HealthIssue.offline,
        ]);
        // Mesma ordem do enum: é a ordem de gravidade.
        final sorted = [...issues]..sort((a, b) => a.index.compareTo(b.index));
        expect(issues, sorted);
      },
    );

    test('com tudo permitido, nenhum problema', () async {
      expect(await build().check(), isEmpty);
    });

    test(
      'sem o canal nativo, não acusa problema que não consegue medir',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        expect(await build().check(), isEmpty);
      },
    );

    test('fora do Android, só o que faz sentido é verificado', () async {
      when(() => dispatcher.hasSmsPermission()).thenAnswer((_) async => false);
      native['isIgnoringBatteryOptimizations'] = false;

      final service = build(isAndroid: false);
      expect(await service.check(), isEmpty);
      expect(service.permissionKinds, [
        HealthIssue.notificationsBlocked,
        HealthIssue.locationDenied,
      ]);
    });
  });

  group('permissionKinds', () {
    test('no Android lista as seis permissões, na ordem da tela', () {
      expect(build().permissionKinds, [
        HealthIssue.notificationsBlocked,
        HealthIssue.smsDenied,
        HealthIssue.locationDenied,
        HealthIssue.exactAlarmsDenied,
        HealthIssue.fullScreenDenied,
        HealthIssue.batteryOptimized,
      ]);
    });
  });

  group('fix', () {
    test('notificações: pede a permissão', () async {
      expect(await build().fix(HealthIssue.notificationsBlocked), isTrue);
      verify(() => notifications.requestPermission()).called(1);
      expect(nativeCalls, isEmpty);
    });

    test(
      'notificações negadas em definitivo: abre as configurações do app',
      () async {
        when(
          () => notifications.requestPermission(),
        ).thenAnswer((_) async => false);
        expect(await build().fix(HealthIssue.notificationsBlocked), isFalse);
        expect(nativeCalls, ['openAppSettings']);
      },
    );

    test('SMS: pede só o SMS', () async {
      await build().fix(HealthIssue.smsDenied);
      verify(() => dispatcher.requestSmsPermission()).called(1);
      verifyNever(() => dispatcher.ensurePermissions());
    });

    test('alarmes exatos: abre a tela do sistema', () async {
      await build().fix(HealthIssue.exactAlarmsDenied);
      verify(() => notifications.requestExactAlarms()).called(1);
    });

    test('bateria e tela cheia: abrem a configuração certa', () async {
      await build().fix(HealthIssue.batteryOptimized);
      await build().fix(HealthIssue.fullScreenDenied);
      expect(nativeCalls, [
        'openBatterySettings',
        'openFullScreenIntentSettings',
      ]);
    });

    test('sem internet e sem contatos não têm correção automática', () async {
      expect(await build().fix(HealthIssue.offline), isFalse);
      expect(await build().fix(HealthIssue.noContacts), isFalse);
      expect(nativeCalls, isEmpty);
    });
  });
}
