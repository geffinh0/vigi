import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/usecases/usecase.dart';
import '../../features/checkin/domain/entities/monitoring_mode_entity.dart';
import '../../features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import '../../features/checkin/domain/usecases/get_available_modes_usecase.dart';
import '../../features/checkin/domain/usecases/start_monitoring_usecase.dart';
import '../../injection/injection_container.dart' as di;
import 'widget_sync_service.dart';

/// Trata a chamada interativa vinda do widget de forma pura e testável.
Future<bool> handleWidgetBackgroundUri(
  Uri? uri, {
  required ConfirmCheckinUseCase confirmCheckinUseCase,
  required WidgetSyncService widgetSyncService,
  StartMonitoringUseCase? startMonitoringUseCase,
  GetAvailableModesUseCase? getAvailableModesUseCase,
}) async {
  if (uri == null) return false;

  final uriString = uri.toString().toLowerCase();

  // 1. Ação: Confirmar Presença ("Estou Bem")
  if (uri.host == 'confirmar_checkin' ||
      uriString.contains('confirmar_checkin')) {
    await confirmCheckinUseCase(const ConfirmCheckinParams());
    await widgetSyncService.updateWidgetData(
      vigiState: 'vigiando',
      minutesRemaining: 60,
      modeName: 'Rotina',
      isMonitoring: true,
    );
    return true;
  }

  // 2. Ação: Iniciar Banho
  if (uri.host == 'iniciar_banho' || uriString.contains('iniciar_banho')) {
    if (startMonitoringUseCase != null) {
      List<MonitoringModeEntity> modes = [];
      if (getAvailableModesUseCase != null) {
        final result = await getAvailableModesUseCase(const NoParams());
        result.fold((_) {}, (list) => modes = list);
      }
      final showerMode = modes
          .where(
            (m) =>
                m.iconKey == 'shower' || m.name.toLowerCase().contains('banho'),
          )
          .firstOrNull;
      final interval = showerMode?.defaultIntervalMinutes ?? 20;
      final modeId = showerMode?.id ?? 'mode-shower';

      await startMonitoringUseCase(
        StartMonitoringParams(
          modeId: modeId,
          intervalOverrideMinutes: interval,
        ),
      );
      await widgetSyncService.updateWidgetData(
        vigiState: 'vigiando',
        minutesRemaining: interval,
        modeName: 'Banho',
        isMonitoring: true,
      );
      return true;
    }
  }

  // 3. Ação: Iniciar Sono
  if (uri.host == 'iniciar_sono' || uriString.contains('iniciar_sono')) {
    if (startMonitoringUseCase != null) {
      List<MonitoringModeEntity> modes = [];
      if (getAvailableModesUseCase != null) {
        final result = await getAvailableModesUseCase(const NoParams());
        result.fold((_) {}, (list) => modes = list);
      }
      final sleepMode = modes
          .where(
            (m) =>
                m.iconKey == 'sleep' || m.name.toLowerCase().contains('sono'),
          )
          .firstOrNull;
      final interval = sleepMode?.defaultIntervalMinutes ?? 480;
      final modeId = sleepMode?.id ?? 'mode-sleep';

      await startMonitoringUseCase(
        StartMonitoringParams(
          modeId: modeId,
          intervalOverrideMinutes: interval,
        ),
      );
      await widgetSyncService.updateWidgetData(
        vigiState: 'noturno',
        minutesRemaining: interval,
        modeName: 'Sono',
        isMonitoring: true,
      );
      return true;
    }
  }

  // O pedido de ajuda nunca sai por um toque só: `pedir_ajuda` abre a tela
  // de pânico no app, onde a pessoa segura o botão por 3 segundos. Por isso
  // não há ação de pânico em segundo plano.

  return false;
}

/// Inicialização mínima necessária para o Isolate de background do widget.
Future<void> bootstrapMinimalForBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
}

/// Callback de background invocado pelo plugin home_widget quando um botão do widget é tocado.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;

  await bootstrapMinimalForBackground();

  final confirmCheckinUseCase = di.sl<ConfirmCheckinUseCase>();
  final widgetSyncService = di.sl<WidgetSyncService>();
  final startMonitoringUseCase = di.sl.isRegistered<StartMonitoringUseCase>()
      ? di.sl<StartMonitoringUseCase>()
      : null;
  final getAvailableModesUseCase =
      di.sl.isRegistered<GetAvailableModesUseCase>()
      ? di.sl<GetAvailableModesUseCase>()
      : null;
  await handleWidgetBackgroundUri(
    uri,
    confirmCheckinUseCase: confirmCheckinUseCase,
    widgetSyncService: widgetSyncService,
    startMonitoringUseCase: startMonitoringUseCase,
    getAvailableModesUseCase: getAvailableModesUseCase,
  );
}
