import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/bluetooth_device.dart';
import 'device_manager.dart';

/// Manages the Windows system-tray icon.
///
/// Displays battery level in the tray icon tooltip and provides a context
/// menu for quick actions (connect, disconnect, show window, quit).
///
/// Uses the `tray_manager` package for cross-platform tray support, plus
/// a MethodChannel for dynamic icon generation showing battery percentage.
class TrayService {
  TrayService({
    required DeviceManager deviceManager,
    Logger? logger,
  })  : _deviceManager = deviceManager,
        _log = logger ?? Logger();

  final DeviceManager _deviceManager;
  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/tray');

  StreamSubscription<BluetoothHeadphone?>? _sub;

  // Callbacks the app registers.
  VoidCallback? onShowWindow;
  VoidCallback? onQuit;
  VoidCallback? onToggleConnect;
  VoidCallback? onShowSettings;

  bool _initialised = false;

  // ── Public API ─────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    _log.i('TrayService: initialising');

    // Set initial icon.
    await _updateTrayIcon(null);

    // Listen for active device changes to update tooltip & icon.
    _sub = _deviceManager.activeDeviceStream.listen(_onDeviceChanged);
  }

  void dispose() {
    _sub?.cancel();
  }

  // ── Internal ───────────────────────────────────────────────────

  void _onDeviceChanged(BluetoothHeadphone? device) {
    _updateTrayIcon(device);
  }

  Future<void> _updateTrayIcon(BluetoothHeadphone? device) async {
    final tooltip = device != null && device.isConnected
        ? '${device.name}\nL: ${device.batteryLeft}%  R: ${device.batteryRight}%'
            '${device.model.hasCase ? "  C: ${device.batteryCase}%" : ""}'
        : 'MagicPods — No device connected';

    try {
      await _channel.invokeMethod('updateTray', {
        'tooltip': tooltip,
        'batteryPercent': device?.batteryAverage ?? -1,
        'isConnected': device?.isConnected ?? false,
        'isCharging': device?.isAnyCharging ?? false,
      });
    } on MissingPluginException {
      // Tray plugin not compiled; ignore silently.
    } catch (e) {
      _log.w('TrayService: failed to update tray', error: e);
    }
  }
}
