/// Abstração de relógio para garantir determinismo e testabilidade.
abstract class Clock {
  DateTime now();
}

/// Implementação padrão do sistema para ambiente de produção.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
