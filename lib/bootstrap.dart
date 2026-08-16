import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/config/app_config.dart';
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
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher Uncaught Error: $error', error, stack);
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase caso as credenciais estejam configuradas
  try {
    if (AppConfig.supabaseUrl.isNotEmpty &&
        AppConfig.supabasePublishableKey.isNotEmpty) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use -- compatibilidade com supabase_flutter v2
        anonKey: AppConfig.supabasePublishableKey,
      );
    }
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar Supabase: $e', e, stack);
  }

  await di.initDependencies();

  runApp(await builder());
}
