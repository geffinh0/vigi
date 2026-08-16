import 'dart:async';
import 'package:flutter/widgets.dart';
import 'core/utils/logger.dart';
import 'injection/injection_container.dart' as di;

/// Função de bootstrap que inicializa bindings, injeção e tratamento de erros.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    AppLogger.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  await di.initDependencies();

  runApp(await builder());
}
