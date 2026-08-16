import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import '../../injection/injection_container.dart' as di;
import 'widget_sync_service.dart';

/// Trata a chamada interativa vinda do widget de forma pura e testável.
Future<bool> handleWidgetBackgroundUri(
  Uri? uri, {
  required ConfirmCheckinUseCase confirmCheckinUseCase,
  required WidgetSyncService widgetSyncService,
}) async {
  if (uri == null) return false;

  final isCheckinAction =
      uri.host == 'confirmar_checkin' ||
      uri.toString().contains('confirmar_checkin');

  if (!isCheckinAction) return false;

  // Executa o caso de uso oficial (salva no Supabase ou enfileira no SyncQueue se offline)
  await confirmCheckinUseCase(const ConfirmCheckinParams());

  // Atualiza o estado do widget para 'normal'
  await widgetSyncService.updateWidgetData(
    vigiState: 'normal',
    minutesRemaining: 60,
    modeName: 'Rotina padrão',
    isMonitoring: true,
  );

  return true;
}

/// Inicialização mínima necessária para o Isolate de background do widget.
Future<void> bootstrapMinimalForBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
}

/// Callback de background invocado pelo plugin home_widget quando o botão é tocado.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;

  final isCheckinAction =
      uri.host == 'confirmar_checkin' ||
      uri.toString().contains('confirmar_checkin');

  if (!isCheckinAction) return;

  await bootstrapMinimalForBackground();

  final confirmCheckinUseCase = di.sl<ConfirmCheckinUseCase>();
  final widgetSyncService = di.sl<WidgetSyncService>();

  await handleWidgetBackgroundUri(
    uri,
    confirmCheckinUseCase: confirmCheckinUseCase,
    widgetSyncService: widgetSyncService,
  );
}
