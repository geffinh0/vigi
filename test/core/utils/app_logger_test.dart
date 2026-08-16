import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/utils/app_logger.dart';

void main() {
  test('AppLogger deve inicializar e registrar mensagens sem exceções', () {
    AppLogger.init();

    expect(() => AppLogger.info('Teste de log de informação'), returnsNormally);
    expect(() => AppLogger.warning('Teste de log de aviso'), returnsNormally);
    expect(() => AppLogger.error('Teste de log de erro'), returnsNormally);
  });
}
