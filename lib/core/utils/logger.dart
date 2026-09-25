import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logger centralizado do projeto VIGI.
///
/// Proíbe o uso de `print` solto no código de produção e garante
/// visibilidade tanto no DevTools quanto no console do terminal.
abstract final class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'Guardiao.DEBUG',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('[DEBUG] $message${error != null ? ' | $error' : ''}');
    }
  }

  static void info(String message) {
    developer.log(message, name: 'Guardiao.INFO');
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    developer.log(message, name: 'Guardiao.WARN', error: error);
    if (kDebugMode) {
      debugPrint('[WARN] $message${error != null ? ' | $error' : ''}');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'Guardiao.ERROR',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ' | $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
