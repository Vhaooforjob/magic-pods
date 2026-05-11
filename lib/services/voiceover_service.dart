import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

import '../models/app_settings.dart';

/// Reads system notifications or alerts aloud using Windows offline TTS.
class VoiceOverService {
  VoiceOverService({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  final FlutterTts _flutterTts = FlutterTts();

  bool _enabled = false;
  bool _isSpeaking = false;

  Future<void> init(AppSettings settings) async {
    _log.i('VoiceOverService: initialising');
    _enabled = settings.voiceOverEnabled;

    try {
      await _flutterTts.setSharedInstance(true);
    } catch (e) {
      _log.w('VoiceOverService: setSharedInstance not supported on this OS');
    }    
    // Configure settings
    await _applySettings(settings);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _log.e('VoiceOverService: TTS error: $msg');
      _isSpeaking = false;
    });
  }

  Future<void> updateSettings(AppSettings settings) async {
    _enabled = settings.voiceOverEnabled;
    await _applySettings(settings);
  }

  Future<void> _applySettings(AppSettings settings) async {
    await _flutterTts.setSpeechRate(settings.voiceOverSpeed);
    
    if (settings.voiceOverVoice != null && settings.voiceOverVoice!.isNotEmpty) {
      // flutter_tts voice format expects {"name": "voiceName", "locale": "en-US"}
      // We'll just set language based on locale setting for now if custom voice is complex
      try {
        await _flutterTts.setLanguage(settings.locale);
      } catch (e) {
        _log.w('Failed to set TTS language: $e');
      }
    } else {
      await _flutterTts.setLanguage(settings.locale);
    }
  }

  /// Get available voices from the OS
  Future<List<dynamic>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices ?? [];
    } catch (e) {
      _log.e('VoiceOverService: failed to get voices', error: e);
      return [];
    }
  }

  /// Speak a notification aloud.
  Future<void> speakNotification(String appName, String title, String body) async {
    if (!_enabled) return;

    // Optional: Stop currently playing TTS to prioritize new notification
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    final textToSpeak = 'Notification from $appName. $title. $body';
    _log.i('VoiceOverService: Speaking: $textToSpeak');
    
    try {
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _log.e('VoiceOverService: failed to speak', error: e);
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}
