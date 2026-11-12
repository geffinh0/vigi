import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/utils/vigi_text.dart';

void main() {
  group('VigiText', () {
    test('firstName: trata a pessoa pelo primeiro nome', () {
      expect(VigiText.firstName('Lúcia Almeida'), 'Lúcia');
      expect(VigiText.firstName('  Maria  '), 'Maria');
      expect(VigiText.firstName(''), '');
      expect(VigiText.firstName(null), '');
    });

    test('initials', () {
      expect(VigiText.initials('Maria Silva'), 'MS');
      expect(VigiText.initials('joão'), 'J');
      expect(VigiText.initials('Ana Maria de Souza'), 'AS');
      expect(VigiText.initials(''), '?');
    });

    test('joinNames: lista como se fala', () {
      expect(VigiText.joinNames(const []), 'seus contatos');
      expect(VigiText.joinNames(['Maria Silva']), 'Maria');
      expect(VigiText.joinNames(['Maria', 'João']), 'Maria e João');
      expect(VigiText.joinNames(['Maria', 'João', 'Ana']), 'Maria, João e Ana');
      expect(
        VigiText.joinNames(['Maria', 'João', 'Ana', 'Rui', 'Bia']),
        'Maria, João e mais 3 pessoas',
      );
      expect(VigiText.joinNames(const [], empty: 'ninguém'), 'ninguém');
    });

    test('greeting: saudação pela hora do dia', () {
      expect(
        VigiText.greeting(DateTime(2026, 9, 30, 8), 'Lúcia'),
        'Bom dia, Lúcia',
      );
      expect(
        VigiText.greeting(DateTime(2026, 9, 30, 14, 22), 'Lúcia'),
        'Boa tarde, Lúcia',
      );
      expect(
        VigiText.greeting(DateTime(2026, 9, 30, 22), 'Lúcia'),
        'Boa noite, Lúcia',
      );
      expect(VigiText.greeting(DateTime(2026, 9, 30, 3)), 'Boa noite');
    });

    test('clock: horário absoluto', () {
      expect(VigiText.clock(DateTime(2026, 9, 30, 15)), '15:00');
      expect(VigiText.clock(DateTime(2026, 9, 30, 7, 5)), '7:05');
      expect(VigiText.clockPadded(DateTime(2026, 9, 30, 8, 10)), '08:10');
    });

    test('clockSpoken: por extenso, para o leitor de tela', () {
      expect(VigiText.clockSpoken(DateTime(2026, 9, 30, 15)), '15 horas');
      expect(
        VigiText.clockSpoken(DateTime(2026, 9, 30, 15, 5)),
        '15 horas e 5 minutos',
      );
      expect(
        VigiText.clockSpoken(DateTime(2026, 9, 30, 1, 1)),
        '1 hora e 1 minuto',
      );
    });

    test('remaining: tempo dentro do anel', () {
      expect(VigiText.remaining(38 * 60), '38 min');
      expect(VigiText.remaining(37 * 60 + 1), '38 min');
      expect(VigiText.remaining(3600), '1 h');
      expect(VigiText.remaining(80 * 60), '1 h 20');
      expect(VigiText.remaining(45), '45 s');
      expect(VigiText.remaining(-5), '0 s');
    });

    test('remainingSpoken', () {
      expect(VigiText.remainingSpoken(38 * 60), '38 minutos');
      expect(VigiText.remainingSpoken(60), '1 minuto');
      expect(VigiText.remainingSpoken(80 * 60), '1 hora e 20 minutos');
      expect(VigiText.remainingSpoken(2 * 3600), '2 horas');
      expect(VigiText.remainingSpoken(1), '1 segundo');
    });

    test('interval: intervalo de um modo', () {
      expect(VigiText.interval(20), '20 min');
      expect(VigiText.interval(60), '1 h');
      expect(VigiText.interval(480), '8 h');
      expect(VigiText.interval(90), '1 h 30');
    });

    test('ringSpoken: frase do anel exigida pelo guia', () {
      expect(
        VigiText.ringSpoken(DateTime(2026, 9, 30, 15), 38 * 60),
        'Próximo check-in às 15 horas, daqui a 38 minutos',
      );
    });

    test('people', () {
      expect(VigiText.people(1), '1 pessoa');
      expect(VigiText.people(3), '3 pessoas');
    });
  });
}
