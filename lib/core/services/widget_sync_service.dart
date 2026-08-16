import 'package:home_widget/home_widget.dart';

/// Interface para sincronização de dados e estado com o widget de tela inicial.
abstract class WidgetSyncService {
  Future<void> updateWidgetData({
    required String vigiState,
    required int minutesRemaining,
    required String modeName,
    required bool isMonitoring,
  });

  Future<void> saveWidgetData<T>(String key, T? value);
  Future<void> updateWidget();
}

/// Implementação padrão que utiliza o plugin [HomeWidget].
class WidgetSyncServiceImpl implements WidgetSyncService {
  const WidgetSyncServiceImpl();

  static const String appWidgetProviderName = 'GuardiaoWidgetProvider';
  static const String iOSWidgetName = 'GuardiaoWidgetExample';

  @override
  Future<void> updateWidgetData({
    required String vigiState,
    required int minutesRemaining,
    required String modeName,
    required bool isMonitoring,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('vigi_state', vigiState);
      await HomeWidget.saveWidgetData<int>(
        'minutes_remaining',
        minutesRemaining,
      );
      await HomeWidget.saveWidgetData<String>('mode_name', modeName);
      await HomeWidget.saveWidgetData<bool>('is_monitoring', isMonitoring);
      await updateWidget();
    } catch (_) {
      // Ignora falhas em ambientes sem suporte nativo
    }
  }

  @override
  Future<void> saveWidgetData<T>(String key, T? value) async {
    try {
      await HomeWidget.saveWidgetData<T>(key, value);
    } catch (_) {}
  }

  @override
  Future<void> updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: appWidgetProviderName,
        androidName: appWidgetProviderName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}
  }
}
