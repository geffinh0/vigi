import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/config/app_config.dart';
import 'core/services/emergency_dispatcher.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_service.dart';
import 'core/services/widget_background_handler.dart';
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

  // Inicializa serviço de notificações locais e canais
  try {
    if (di.sl.isRegistered<NotificationService>()) {
      await di.sl<NotificationService>().initialize();
    }
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar NotificationService: $e', e, stack);
  }

  // Registra o token FCM deste aparelho para receber alertas dos vinculados
  try {
    if (di.sl.isRegistered<PushService>()) {
      await di.sl<PushService>().initialize();
    }
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar PushService: $e', e, stack);
  }

  // Pede antecipadamente as permissões de SMS e localização, para que no
  // momento da emergência o alerta saia sem nenhum diálogo pendente.
  if (di.sl.isRegistered<EmergencyDispatcher>()) {
    unawaited(di.sl<EmergencyDispatcher>().ensurePermissions());
  }

  // Registra callback interativo para o Widget de Tela Inicial
  try {
    await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  } catch (e, stack) {
    AppLogger.error('Erro ao registrar callback do HomeWidget: $e', e, stack);
  }

  runApp(await builder());
}
