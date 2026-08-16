import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

abstract class AlarmService {
  Future<void> startAlert();
  Future<void> stopAlert();
  bool get isAlerting;
}

class AlarmServiceImpl implements AlarmService {
  AlarmServiceImpl({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;
  bool _isAlerting = false;
  Timer? _hapticTimer;

  @override
  bool get isAlerting => _isAlerting;

  @override
  Future<void> startAlert() async {
    if (_isAlerting) return;
    _isAlerting = true;

    try {
      // Configura reprodução contínua em loop com volume máximo
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      // Usa asset ou fallback sonoro de alarme
      await _audioPlayer.play(
        AssetSource('audio/alarm.mp3'),
      );
    } catch (_) {
      // Fallback: se o asset não estiver presente no ambiente de teste/debug, continua com vibração
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(
          pattern: [500, 500, 500, 500],
          repeat: 0,
        );
      } else {
        _startHapticFallback();
      }
    } catch (_) {
      _startHapticFallback();
    }
  }

  void _startHapticFallback() {
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_isAlerting) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Future<void> stopAlert() async {
    _isAlerting = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
