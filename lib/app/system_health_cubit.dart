import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/system_health_service.dart';

/// Problemas que comprometem a proteção agora (faixa do topo da tela
/// inicial). Reverifica quando a conexão muda e quando o app volta ao
/// primeiro plano.
class SystemHealthCubit extends Cubit<List<HealthIssue>> {
  SystemHealthCubit([this._service]) : super(const []) {
    _subscription = _service?.changes.listen((_) => refresh());
  }

  final SystemHealthService? _service;
  StreamSubscription<void>? _subscription;

  Future<void> refresh() async {
    final service = _service;
    if (service == null || isClosed) return;
    try {
      final issues = await service.check();
      if (!isClosed) emit(issues);
    } catch (_) {
      // Verificação indisponível: não acusa um problema que não existe.
    }
  }

  /// Leva a pessoa direto à correção e reverifica.
  Future<void> fix(HealthIssue issue) async {
    await _service?.fix(issue);
    await refresh();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
