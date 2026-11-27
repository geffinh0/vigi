import 'dart:async';
import 'dart:io';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Configuração de todos os testes.
///
/// As imagens de referência (goldens) são geradas no Linux, o mesmo sistema
/// do CI. Em outros sistemas o desenho de bordas e sombras muda alguns
/// pixels, então a comparação de imagem é pulada; o restante de cada teste
/// (estados, textos, ausência de estouro de layout) roda normalmente.
///
/// Para regenerar: `flutter test --update-goldens` no Linux, WSL ou CI.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async => testMain(),
    config: GoldenToolkitConfiguration(
      skipGoldenAssertion: () => !Platform.isLinux,
    ),
  );
}
