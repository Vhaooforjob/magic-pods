import 'package:equatable/equatable.dart';

/// Persisted user settings.
class AppSettings extends Equatable {
  const AppSettings({
    this.earDetectionEnabled = true,
    this.autoSwitchAudioOutput = true,
    this.lowBatteryNotification = true,
    this.lowBatteryThreshold = 20,
    this.criticalBatteryThreshold = 10,
    this.showPopupOnLidOpen = true,
    this.popupDurationSeconds = 5,
    this.voiceOverEnabled = false,
    this.voiceOverVoice,
    this.voiceOverSpeed = 1.0,
    this.startMinimized = false,
    this.startWithWindows = false,
    this.minimizeToTray = true,
    this.showTrayIcon = true,
    this.trayShowBattery = true,
    this.hotkeyConnect = 'Ctrl+Alt+A',
    this.hotkeySwitchOutput = 'Ctrl+Alt+S',
    this.hotkeyShowBattery = 'Ctrl+Alt+B',
    this.a2dpSinkEnabled = false,
    this.preferredSpeakerDeviceId,
    this.locale = 'en',
  });

  // ── Ear Detection ──────────────────────────────────────────────
  final bool earDetectionEnabled;

  // ── Audio ──────────────────────────────────────────────────────
  final bool autoSwitchAudioOutput;
  final String? preferredSpeakerDeviceId;

  // ── Battery ────────────────────────────────────────────────────
  final bool lowBatteryNotification;
  final int lowBatteryThreshold;
  final int criticalBatteryThreshold;

  // ── Popup ──────────────────────────────────────────────────────
  final bool showPopupOnLidOpen;
  final int popupDurationSeconds;

  // ── VoiceOver ──────────────────────────────────────────────────
  final bool voiceOverEnabled;
  final String? voiceOverVoice;
  final double voiceOverSpeed;

  // ── System ─────────────────────────────────────────────────────
  final bool startMinimized;
  final bool startWithWindows;
  final bool minimizeToTray;
  final bool showTrayIcon;
  final bool trayShowBattery;

  // ── Hotkeys ────────────────────────────────────────────────────
  final String hotkeyConnect;
  final String hotkeySwitchOutput;
  final String hotkeyShowBattery;

  // ── A2DP Sink ──────────────────────────────────────────────────
  final bool a2dpSinkEnabled;

  // ── Locale ─────────────────────────────────────────────────────
  final String locale;

  AppSettings copyWith({
    bool? earDetectionEnabled,
    bool? autoSwitchAudioOutput,
    bool? lowBatteryNotification,
    int? lowBatteryThreshold,
    int? criticalBatteryThreshold,
    bool? showPopupOnLidOpen,
    int? popupDurationSeconds,
    bool? voiceOverEnabled,
    String? voiceOverVoice,
    double? voiceOverSpeed,
    bool? startMinimized,
    bool? startWithWindows,
    bool? minimizeToTray,
    bool? showTrayIcon,
    bool? trayShowBattery,
    String? hotkeyConnect,
    String? hotkeySwitchOutput,
    String? hotkeyShowBattery,
    bool? a2dpSinkEnabled,
    String? preferredSpeakerDeviceId,
    String? locale,
  }) {
    return AppSettings(
      earDetectionEnabled: earDetectionEnabled ?? this.earDetectionEnabled,
      autoSwitchAudioOutput: autoSwitchAudioOutput ?? this.autoSwitchAudioOutput,
      lowBatteryNotification: lowBatteryNotification ?? this.lowBatteryNotification,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      criticalBatteryThreshold: criticalBatteryThreshold ?? this.criticalBatteryThreshold,
      showPopupOnLidOpen: showPopupOnLidOpen ?? this.showPopupOnLidOpen,
      popupDurationSeconds: popupDurationSeconds ?? this.popupDurationSeconds,
      voiceOverEnabled: voiceOverEnabled ?? this.voiceOverEnabled,
      voiceOverVoice: voiceOverVoice ?? this.voiceOverVoice,
      voiceOverSpeed: voiceOverSpeed ?? this.voiceOverSpeed,
      startMinimized: startMinimized ?? this.startMinimized,
      startWithWindows: startWithWindows ?? this.startWithWindows,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      showTrayIcon: showTrayIcon ?? this.showTrayIcon,
      trayShowBattery: trayShowBattery ?? this.trayShowBattery,
      hotkeyConnect: hotkeyConnect ?? this.hotkeyConnect,
      hotkeySwitchOutput: hotkeySwitchOutput ?? this.hotkeySwitchOutput,
      hotkeyShowBattery: hotkeyShowBattery ?? this.hotkeyShowBattery,
      a2dpSinkEnabled: a2dpSinkEnabled ?? this.a2dpSinkEnabled,
      preferredSpeakerDeviceId: preferredSpeakerDeviceId ?? this.preferredSpeakerDeviceId,
      locale: locale ?? this.locale,
    );
  }

  /// Serialise to a plain map for [SharedPreferences].
  Map<String, dynamic> toMap() => {
        'earDetectionEnabled': earDetectionEnabled,
        'autoSwitchAudioOutput': autoSwitchAudioOutput,
        'lowBatteryNotification': lowBatteryNotification,
        'lowBatteryThreshold': lowBatteryThreshold,
        'criticalBatteryThreshold': criticalBatteryThreshold,
        'showPopupOnLidOpen': showPopupOnLidOpen,
        'popupDurationSeconds': popupDurationSeconds,
        'voiceOverEnabled': voiceOverEnabled,
        'voiceOverVoice': voiceOverVoice,
        'voiceOverSpeed': voiceOverSpeed,
        'startMinimized': startMinimized,
        'startWithWindows': startWithWindows,
        'minimizeToTray': minimizeToTray,
        'showTrayIcon': showTrayIcon,
        'trayShowBattery': trayShowBattery,
        'hotkeyConnect': hotkeyConnect,
        'hotkeySwitchOutput': hotkeySwitchOutput,
        'hotkeyShowBattery': hotkeyShowBattery,
        'a2dpSinkEnabled': a2dpSinkEnabled,
        'preferredSpeakerDeviceId': preferredSpeakerDeviceId,
        'locale': locale,
      };

  /// Deserialise from a plain map.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      earDetectionEnabled: map['earDetectionEnabled'] as bool? ?? true,
      autoSwitchAudioOutput: map['autoSwitchAudioOutput'] as bool? ?? true,
      lowBatteryNotification: map['lowBatteryNotification'] as bool? ?? true,
      lowBatteryThreshold: map['lowBatteryThreshold'] as int? ?? 20,
      criticalBatteryThreshold: map['criticalBatteryThreshold'] as int? ?? 10,
      showPopupOnLidOpen: map['showPopupOnLidOpen'] as bool? ?? true,
      popupDurationSeconds: map['popupDurationSeconds'] as int? ?? 5,
      voiceOverEnabled: map['voiceOverEnabled'] as bool? ?? false,
      voiceOverVoice: map['voiceOverVoice'] as String?,
      voiceOverSpeed: (map['voiceOverSpeed'] as num?)?.toDouble() ?? 1.0,
      startMinimized: map['startMinimized'] as bool? ?? false,
      startWithWindows: map['startWithWindows'] as bool? ?? false,
      minimizeToTray: map['minimizeToTray'] as bool? ?? true,
      showTrayIcon: map['showTrayIcon'] as bool? ?? true,
      trayShowBattery: map['trayShowBattery'] as bool? ?? true,
      hotkeyConnect: map['hotkeyConnect'] as String? ?? 'Ctrl+Alt+A',
      hotkeySwitchOutput: map['hotkeySwitchOutput'] as String? ?? 'Ctrl+Alt+S',
      hotkeyShowBattery: map['hotkeyShowBattery'] as String? ?? 'Ctrl+Alt+B',
      a2dpSinkEnabled: map['a2dpSinkEnabled'] as bool? ?? false,
      preferredSpeakerDeviceId: map['preferredSpeakerDeviceId'] as String?,
      locale: map['locale'] as String? ?? 'en',
    );
  }

  @override
  List<Object?> get props => [
        earDetectionEnabled,
        autoSwitchAudioOutput,
        lowBatteryNotification,
        lowBatteryThreshold,
        criticalBatteryThreshold,
        showPopupOnLidOpen,
        popupDurationSeconds,
        voiceOverEnabled,
        voiceOverVoice,
        voiceOverSpeed,
        startMinimized,
        startWithWindows,
        minimizeToTray,
        showTrayIcon,
        trayShowBattery,
        hotkeyConnect,
        hotkeySwitchOutput,
        hotkeyShowBattery,
        a2dpSinkEnabled,
        preferredSpeakerDeviceId,
        locale,
      ];
}
