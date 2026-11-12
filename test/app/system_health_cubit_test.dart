import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/app/system_health_cubit.dart';
import 'package:guardiao/core/services/system_health_service.dart';
import 'package:guardiao/core/widgets/health_banner.dart';
import 'package:mocktail/mocktail.dart';

class MockSystemHealthService extends Mock implements SystemHealthService {}

void main() {
  late MockSystemHealthService service;
  late StreamController<void> changes;

  setUpAll(() {
    registerFallbackValue(HealthIssue.offline);
  });

  setUp(() {
    service = MockSystemHealthService();
    changes = StreamController<void>.broadcast();
    when(() => service.changes).thenAnswer((_) => changes.stream);
    when(() => service.check()).thenAnswer((_) async => const []);
    when(() => service.fix(any())).thenAnswer((_) async => true);
  });

  tearDown(() => changes.close());

  group('SystemHealthCubit', () {
    test('começa sem problemas', () {
      expect(SystemHealthCubit(service).state, isEmpty);
    });

    blocTest<SystemHealthCubit, List<HealthIssue>>(
      'refresh publica os problemas encontrados',
      build: () {
        when(() => service.check()).thenAnswer(
          (_) async => const [
            HealthIssue.notificationsBlocked,
            HealthIssue.batteryOptimized,
          ],
        );
        return SystemHealthCubit(service);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const [HealthIssue.notificationsBlocked, HealthIssue.batteryOptimized],
      ],
    );

    blocTest<SystemHealthCubit, List<HealthIssue>>(
      'reverifica sozinho quando a conexão muda',
      build: () {
        when(
          () => service.check(),
        ).thenAnswer((_) async => const [HealthIssue.offline]);
        return SystemHealthCubit(service);
      },
      act: (cubit) => changes.add(null),
      wait: const Duration(milliseconds: 20),
      expect: () => [
        const [HealthIssue.offline],
      ],
    );

    blocTest<SystemHealthCubit, List<HealthIssue>>(
      'fix leva à correção e reverifica',
      build: () {
        var fixed = false;
        when(() => service.fix(HealthIssue.notificationsBlocked)).thenAnswer((
          _,
        ) async {
          fixed = true;
          return true;
        });
        when(() => service.check()).thenAnswer(
          (_) async =>
              fixed ? const [] : const [HealthIssue.notificationsBlocked],
        );
        return SystemHealthCubit(service);
      },
      act: (cubit) async {
        await cubit.refresh();
        await cubit.fix(HealthIssue.notificationsBlocked);
      },
      expect: () => [
        const [HealthIssue.notificationsBlocked],
        const <HealthIssue>[],
      ],
      verify: (_) {
        verify(() => service.fix(HealthIssue.notificationsBlocked)).called(1);
      },
    );

    blocTest<SystemHealthCubit, List<HealthIssue>>(
      'se a verificação falhar, não acusa problema que não existe',
      build: () {
        when(() => service.check()).thenThrow(Exception('sem plugin'));
        return SystemHealthCubit(service);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => <List<HealthIssue>>[],
    );

    test('sem serviço (testes, web) fica vazio', () async {
      final cubit = SystemHealthCubit();
      await cubit.refresh();
      expect(cubit.state, isEmpty);
    });
  });

  group('textos da faixa de saúde', () {
    test('todo problema tem título e explicação em linguagem clara', () {
      final shouting = RegExp(r'\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{4,}\b');
      for (final issue in HealthIssue.values) {
        expect(issue.title, isNotEmpty);
        expect(issue.detail, isNotEmpty);
        expect(shouting.hasMatch('${issue.title} ${issue.detail}'), isFalse);
      }
    });

    test('todo problema que a pessoa pode resolver tem um botão', () {
      expect(HealthIssue.notificationsBlocked.action, 'Permitir');
      expect(HealthIssue.smsDenied.action, 'Permitir');
      expect(HealthIssue.locationDenied.action, 'Permitir');
      expect(HealthIssue.batteryOptimized.action, 'Ajustar');
      expect(HealthIssue.noContacts.action, 'Escolher');
      // Sem internet não há o que tocar: o Vigi só informa.
      expect(HealthIssue.offline.action, isNull);
    });
  });
}
