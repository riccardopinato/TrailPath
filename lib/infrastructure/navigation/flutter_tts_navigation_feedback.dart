import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class FlutterTtsNavigationFeedback implements NavigationFeedback {
  FlutterTtsNavigationFeedback() : _tts = FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> configure(String languageCode) async {
    final language = switch (languageCode) {
      'it' => 'it-IT',
      'es' => 'es-ES',
      'fr' => 'fr-FR',
      'pt' => 'pt-PT',
      _ => 'en-US',
    };
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> speak(String message) async {
    if (message.trim().isEmpty) {
      return;
    }
    await _tts.stop();
    await _tts.speak(message);
  }

  @override
  Future<void> alert() => HapticFeedback.heavyImpact();

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
