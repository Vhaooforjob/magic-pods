import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// StateNotifier to manage and persist AppSettings.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_loadSettings(_prefs));

  final SharedPreferences _prefs;
  static const _prefsKey = 'magic_pods_settings';

  static AppSettings _loadSettings(SharedPreferences prefs) {
    final str = prefs.getString(_prefsKey);
    if (str != null) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return AppSettings.fromMap(map);
      } catch (e) {
        // Fallback to defaults on error
      }
    }
    return const AppSettings();
  }

  void updateSettings(AppSettings newSettings) {
    state = newSettings;
    _prefs.setString(_prefsKey, jsonEncode(state.toMap()));
  }

  // ── Convenience Mutators ───────────────────────────────────────

  void setEarDetection(bool enabled) {
    updateSettings(state.copyWith(earDetectionEnabled: enabled));
  }

  void setAutoSwitchAudio(bool enabled) {
    updateSettings(state.copyWith(autoSwitchAudioOutput: enabled));
  }

  void setLowBatteryNotification(bool enabled) {
    updateSettings(state.copyWith(lowBatteryNotification: enabled));
  }

  void setVoiceOver(bool enabled) {
    updateSettings(state.copyWith(voiceOverEnabled: enabled));
  }
}

/// Provider for SharedPreferences (must be overridden in ProviderScope during app init).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Exposes the AppSettings and allows mutations.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
