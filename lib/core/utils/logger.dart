import 'dart:developer' as developer;

/// Logger centralizado do projeto Guardião.
///
/// Proíbe o uso de `print` solto no código de produção.
abstract final class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'Guardiao.DEBUG',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message) {
    developer.log(message, name: 'Guardiao.INFO');
  }

  static void warning(String message, [Object? error]) {
    developer.log(message, name: 'Guardiao.WARN', error: error);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'Guardiao.ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
