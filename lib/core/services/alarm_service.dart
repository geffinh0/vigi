import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Som e vibração da escada de estados (Guia de Design, seção 11).
///
/// | Momento          | Som                                   | Vibração                          |
/// |------------------|---------------------------------------|-----------------------------------|
/// | Sua vez          | duas notas, a cada 30 s               | dois pulsos curtos, a cada 30 s   |
/// | Última chamada   | as mesmas notas, rápidas, crescendo   | pulsos longos contínuos           |
/// | Alerta           | uma vez, mais grave e firme           | um pulso longo de 800 ms          |
/// | Confirmação      | nenhum                                | um pulso suave de 40 ms           |
///
/// O som da chamada não pode parecer sirene: a pessoa vai ouvi-lo várias
/// vezes por dia e precisa não se assustar. Confirmação e pânico não têm som
/// próprio; em uma situação de risco, fazer barulho pode não ser desejado.
abstract class AlarmService {
  /// "Sua vez": repete a chamada a cada 30 segundos até [stopAlert].
  ///
  /// A primeira chamada sai pela notificação (que toca mesmo com o app
  /// fechado); este serviço cuida das repetições.
  Future<void> startCall();

  /// "Última chamada": vibração constante e, se [playSound], o alarme em
  /// laço com volume crescente. Com as notificações ligadas o som já vem da
  /// própria notificação, então [playSound] fica falso.
  Future<void> startLastCall({bool playSound = false});

  /// Os contatos foram avisados: um som grave e firme, uma única vez.
  Future<void> playAlertConfirmed();

  /// A pessoa confirmou: só um pulso suave, sem som.
  Future<void> confirmFeedback();

  /// Silencia tudo.
  Future<void> stopAlert();

  bool get isAlerting;
}

/// Implementação de [AlarmService] com audioplayers e vibration.
class AlarmServiceImpl implements AlarmService {
  AlarmServiceImpl({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;
  bool _isAlerting = false;
  Timer? _repeatTimer;
  Timer? _volumeTimer;

  static const Duration callInterval = Duration(seconds: 30);

  @override
  bool get isAlerting => _isAlerting;

  @override
  Future<void> startCall() async {
    await _silence();
    _isAlerting = true;
    _repeatTimer = Timer.periodic(callInterval, (_) {
      if (!_isAlerting) return;
      unawaited(_play('audio/chamada.wav', alarmStream: false));
      unawaited(_vibrate(pattern: const [0, 80, 120, 80]));
    });
  }

  @override
  Future<void> startLastCall({bool playSound = false}) async {
    await _silence();
    _isAlerting = true;

    unawaited(_vibrate(pattern: const [0, 600, 400], repeat: 0));

    if (!playSound) return;
    // Volume crescente até o máximo do aparelho.
    var volume = 0.3;
    await _play(
      'audio/ultima_chamada.wav',
      alarmStream: true,
      loop: true,
      volume: volume,
    );
    _volumeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isAlerting) {
        timer.cancel();
        return;
      }
      volume = (volume + 0.1).clamp(0.0, 1.0);
      unawaited(_setVolume(volume));
      if (volume >= 1.0) timer.cancel();
    });
  }

  @override
  Future<void> playAlertConfirmed() async {
    await _silence();
    unawaited(_play('audio/alerta.wav', alarmStream: true));
    unawaited(_vibrate(duration: 800));
  }

  @override
  Future<void> confirmFeedback() => _vibrate(duration: 40, amplitude: 80);

  @override
  Future<void> stopAlert() => _silence();

  Future<void> _silence() async {
    _isAlerting = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _volumeTimer?.cancel();
    _volumeTimer = null;

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<void> _play(
    String asset, {
    required bool alarmStream,
    bool loop = false,
    double volume = 1,
  }) async {
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            stayAwake: alarmStream,
            contentType: AndroidContentType.sonification,
            // O canal de ALARME toca mesmo no modo silencioso; a chamada
            // gentil respeita o volume de notificações.
            usageType: alarmStream
                ? AndroidUsageType.alarm
                : AndroidUsageType.notification,
            audioFocus: alarmStream
                ? AndroidAudioFocus.gainTransientExclusive
                : AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(AssetSource(asset));
    } catch (_) {
      // Sem áudio (ex.: ambiente de teste): a vibração e a notificação
      // continuam avisando.
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (_) {}
  }

  Future<void> _vibrate({
    List<int>? pattern,
    int duration = 0,
    int repeat = -1,
    int amplitude = -1,
  }) => VigiHaptics.vibrate(
    pattern: pattern,
    duration: duration,
    repeat: repeat,
    amplitude: amplitude,
  );
}

/// Vibração com tolerância a aparelhos (e testes) sem motor de vibração.
abstract final class VigiHaptics {
  /// Vibra por [duration] ms, ou segue [pattern] (espera, vibra, espera...).
  static Future<void> vibrate({
    List<int>? pattern,
    int duration = 0,
    int repeat = -1,
    int amplitude = -1,
  }) async {
    try {
      if (!await Vibration.hasVibrator()) {
        await HapticFeedback.mediumImpact();
        return;
      }
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern, repeat: repeat);
      } else {
        await Vibration.vibrate(duration: duration, amplitude: amplitude);
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  /// Pânico, durante o gesto: um pulso curto por segundo.
  static Future<void> holdTick() => vibrate(duration: 60);

  /// Pânico acionado: um pulso longo de 800 ms.
  static Future<void> panicTriggered() => vibrate(duration: 800);

  /// Confirmação: um pulso suave de 40 ms.
  static Future<void> confirm() => vibrate(duration: 40, amplitude: 80);
}
