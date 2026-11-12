import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/services/checkin_messages.dart';
import 'package:guardiao/core/services/notification_service.dart';

void main() {
  group('NotificationService: decisão pura de prazo vencido', () {
    final deadline = DateTime(2026, 8, 16, 14);

    test('verdadeiro quando o horário atual é exatamente o prazo', () {
      expect(
        NotificationService.shouldTriggerAlert(
          nextDeadline: deadline,
          currentTime: DateTime(2026, 8, 16, 14),
        ),
        isTrue,
      );
    });

    test('verdadeiro quando o prazo já passou', () {
      expect(
        NotificationService.shouldTriggerAlert(
          nextDeadline: deadline,
          currentTime: DateTime(2026, 8, 16, 14, 0, 1),
        ),
        isTrue,
      );
    });

    test('falso quando o prazo ainda não chegou', () {
      expect(
        NotificationService.shouldTriggerAlert(
          nextDeadline: deadline,
          currentTime: DateTime(2026, 8, 16, 13, 59, 59),
        ),
        isFalse,
      );
    });
  });

  group('NotificationService: canais e ações', () {
    test('um canal por degrau da escada', () {
      expect(NotificationService.channelIdVigilia, 'lembrete_checkin');
      expect(NotificationService.channelIdChamada, 'vigi_chamada');
      expect(NotificationService.channelIdUltimaChamada, 'vigi_ultima_chamada');
      // O push para familiares depende deste identificador.
      expect(NotificationService.channelIdAlerta, 'alerta_checkin');
    });

    test('nomes dos canais sem caixa alta', () {
      for (final name in [
        NotificationService.channelNameVigilia,
        NotificationService.channelNameChamada,
        NotificationService.channelNameUltimaChamada,
        NotificationService.channelNameAlerta,
      ]) {
        expect(name, isNot(name.toUpperCase()));
      }
    });

    test('vibração: dois pulsos curtos na vez, pulsos longos na última', () {
      expect(NotificationService.vibrationChamada, [0, 80, 120, 80]);
      expect(
        NotificationService.vibrationUltimaChamada.sublist(0, 3),
        [0, 600, 400],
      );
    });

    test('ações da notificação: "Estou bem" e "+10 min"', () {
      expect(
        NotificationAction.fromId('estou_bem'),
        NotificationAction.confirm,
      );
      expect(NotificationAction.fromId('mais_10'), NotificationAction.snooze);
      expect(NotificationAction.fromId('outra'), isNull);
      expect(NotificationAction.fromId(null), isNull);
    });
  });

  group('CheckinMessages', () {
    final escalatesAt = DateTime(2026, 9, 30, 15, 15);

    test('a chamada é uma pergunta humana, pelo primeiro nome', () {
      expect(CheckinMessages.question('Lúcia'), 'Tudo bem por aí, Lúcia?');
      expect(CheckinMessages.question(''), 'Tudo bem por aí?');
    });

    test('sempre diz o que vem a seguir, quando, e para quem', () {
      expect(
        CheckinMessages.consequence(escalatesAt, ['Maria Silva', 'João']),
        'Se você não responder até 15:15, vamos avisar Maria e João.',
      );
      expect(
        CheckinMessages.consequence(escalatesAt, const []),
        'Se você não responder até 15:15, vamos avisar seus contatos.',
      );
    });

    test('corpo da notificação de chamada', () {
      expect(
        CheckinMessages.callBody(escalatesAt, ['Maria', 'João']),
        'Toque em Estou bem. Se não responder até 15:15, avisamos Maria e '
        'João.',
      );
    });

    test('alerta: o que foi feito, para quantos e quando', () {
      expect(CheckinMessages.alertedTitle, 'Pedimos ajuda por você');
      expect(
        CheckinMessages.alertedBody(
          notified: 3,
          at: DateTime(2026, 9, 30, 14, 7),
          withLocation: true,
        ),
        'Avisamos 3 pessoas às 14:07 com a sua localização.',
      );
      expect(
        CheckinMessages.alertedBody(
          notified: 1,
          at: DateTime(2026, 9, 30, 14, 7),
          withLocation: false,
        ),
        'Avisamos 1 pessoa às 14:07.',
      );
    });

    test('aliviado: agradece e diz o próximo horário', () {
      final next = DateTime(2026, 9, 30, 16);
      expect(
        CheckinMessages.relief(next),
        'Obrigado. Próximo check-in às 16:00.',
      );
      expect(
        CheckinMessages.relief(next, afterAlert: true),
        'Obrigado. Próximo check-in às 16:00. Avisamos seus contatos de que '
        'está tudo bem.',
      );
    });

    test('quem está de vigília', () {
      expect(
        CheckinMessages.watching(['Maria Silva', 'João']),
        'Maria e João estão de vigília com você',
      );
      expect(
        CheckinMessages.watching(['Maria']),
        'Maria está de vigília com você',
      );
      expect(
        CheckinMessages.watching(const []),
        'Ninguém está de vigília com você ainda',
      );
    });

    test('chip do modo ativo', () {
      expect(
        CheckinMessages.modeChip(
          modeName: 'Rotina',
          intervalMinutes: 60,
          isSleep: false,
        ),
        'Rotina, a cada 1 h',
      );
      expect(
        CheckinMessages.modeChip(
          modeName: 'Sono',
          intervalMinutes: 480,
          isSleep: true,
          deadline: DateTime(2026, 10, 1, 7),
        ),
        'Sono, até 7:00',
      );
    });

    test('nenhum texto da escada grita em caixa alta', () {
      final texts = [
        CheckinMessages.question('Lúcia'),
        CheckinMessages.consequence(escalatesAt, ['Maria']),
        CheckinMessages.lastCallTitle('Lúcia'),
        CheckinMessages.lastCallBody(escalatesAt, ['Maria']),
        CheckinMessages.alertedTitle,
      ];
      final shouting = RegExp(r'\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,}\b');
      for (final text in texts) {
        expect(shouting.hasMatch(text), isFalse, reason: text);
      }
    });
  });
}
