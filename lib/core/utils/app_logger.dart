import 'package:logging/logging.dart';

/// Logger baseado no pacote `logging` (canal "VIGI").
abstract class AppLogger {
  static final Logger _logger = Logger('VIGI');

  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Formatação padronizada de logs
      // ignore: avoid_print
      print(
        '${record.time} [${record.level.name}] ${record.loggerName}: ${record.message}',
      );
    });
  }

  static void info(String message) => _logger.info(message);

  static void warning(String message) => _logger.warning(message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.shout(message, error, stackTrace);
  }
}
