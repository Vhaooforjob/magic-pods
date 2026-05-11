import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/app_settings.dart';
import '../models/audio_device.dart';
import '../models/bluetooth_device.dart';
import '../services/audio_service.dart';
import '../services/battery_notification_service.dart';
import '../services/ble_scanner_service.dart';
import '../services/bluetooth_connection_service.dart';
import '../services/device_manager.dart';
import '../services/ear_detection_service.dart';
import '../services/hotkey_service.dart';
import '../services/tray_service.dart';
import '../services/voiceover_service.dart';
import 'settings_provider.dart';

// ── Core Services ──────────────────────────────────────────────────

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );
});

final bleScannerProvider = Provider<BleScanner>((ref) {
  final logger = ref.watch(loggerProvider);
  final scanner = BleScanner(logger: logger);
  ref.onDispose(() => scanner.dispose());
  return scanner;
});

final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final scanner = ref.watch(bleScannerProvider);
  final logger = ref.watch(loggerProvider);
  final manager = DeviceManager(bleScanner: scanner, logger: logger);
  // Manager is initialized in the app boot sequence
  ref.onDispose(() => manager.dispose());
  return manager;
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final logger = ref.watch(loggerProvider);
  final service = AudioService(logger: logger);
  ref.onDispose(() => service.dispose());
  return service;
});

final bluetoothConnectionServiceProvider = Provider<BluetoothConnectionService>((ref) {
  final logger = ref.watch(loggerProvider);
  return BluetoothConnectionService(logger: logger);
});

// ── Feature Services ───────────────────────────────────────────────

final earDetectionServiceProvider = Provider<EarDetectionService>((ref) {
  final deviceManager = ref.watch(deviceManagerProvider);
  final logger = ref.watch(loggerProvider);
  final service = EarDetectionService(deviceManager: deviceManager, logger: logger);
  
  // Watch settings to enable/disable
  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    if (previous?.earDetectionEnabled != next.earDetectionEnabled) {
      service.enabled = next.earDetectionEnabled;
      if (next.earDetectionEnabled) {
        service.start();
      } else {
        service.stop();
      }
    }
  });

  ref.onDispose(() => service.dispose());
  return service;
});

final batteryNotificationServiceProvider = Provider<BatteryNotificationService>((ref) {
  final deviceManager = ref.watch(deviceManagerProvider);
  final logger = ref.watch(loggerProvider);
  final service = BatteryNotificationService(deviceManager: deviceManager, logger: logger);

  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    service.enabled = next.lowBatteryNotification;
    service.warningThreshold = next.lowBatteryThreshold;
    service.criticalThreshold = next.criticalBatteryThreshold;
  });

  ref.onDispose(() => service.dispose());
  return service;
});

final trayServiceProvider = Provider<TrayService>((ref) {
  final deviceManager = ref.watch(deviceManagerProvider);
  final logger = ref.watch(loggerProvider);
  final service = TrayService(deviceManager: deviceManager, logger: logger);
  ref.onDispose(() => service.dispose());
  return service;
});

final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  final deviceManager = ref.watch(deviceManagerProvider);
  final audioService = ref.watch(audioServiceProvider);
  final logger = ref.watch(loggerProvider);
  final service = HotkeyService(deviceManager: deviceManager, audioService: audioService, logger: logger);
  ref.onDispose(() => service.dispose());
  return service;
});

final voiceOverServiceProvider = Provider<VoiceOverService>((ref) {
  final logger = ref.watch(loggerProvider);
  final service = VoiceOverService(logger: logger);
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Streams / State ────────────────────────────────────────────────

final devicesStreamProvider = StreamProvider<List<BluetoothHeadphone>>((ref) {
  return ref.watch(deviceManagerProvider).devicesStream;
});

final activeDeviceStreamProvider = StreamProvider<BluetoothHeadphone?>((ref) {
  return ref.watch(deviceManagerProvider).activeDeviceStream;
});

final audioDevicesStreamProvider = StreamProvider<List<AudioDevice>>((ref) {
  return ref.watch(audioServiceProvider).devicesStream;
});

final defaultAudioDeviceStreamProvider = StreamProvider<AudioDevice?>((ref) {
  return ref.watch(audioServiceProvider).defaultDeviceStream;
});
