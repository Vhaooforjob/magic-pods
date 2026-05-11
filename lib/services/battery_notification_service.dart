import 'dart:async';
import 'package:logger/logger.dart';
import '../models/bluetooth_device.dart';
import 'device_manager.dart';

/// Notification priority levels.
enum BatteryAlertLevel { none, warning, critical, urgent }

/// Callback signature for battery notifications.
typedef BatteryAlertCallback = void Function(
    BluetoothHeadphone device, BatteryAlertLevel level, int percentage);

/// Monitors battery levels of connected devices and fires callbacks
/// when thresholds are crossed.
///
/// Implements hysteresis to avoid repeated alerts for the same threshold.
class BatteryNotificationService {
  BatteryNotificationService({
    required DeviceManager deviceManager,
    Logger? logger,
    this.warningThreshold = 20,
    this.criticalThreshold = 10,
    this.urgentThreshold = 5,
  })  : _deviceManager = deviceManager,
        _log = logger ?? Logger();

  final DeviceManager _deviceManager;
  final Logger _log;

  int warningThreshold;
  int criticalThreshold;
  int urgentThreshold;

  StreamSubscription<BluetoothHeadphone?>? _sub;
  bool _enabled = true;

  /// Track which alerts have already been fired per device address
  /// to prevent spamming.
  final Map<String, BatteryAlertLevel> _lastAlertLevel = {};

  BatteryAlertCallback? onAlert;

  // ── Public API ─────────────────────────────────────────────────

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void start() {
    _sub?.cancel();
    _sub = _deviceManager.activeDeviceStream.listen(_check);
    _log.i('BatteryNotificationService: started');
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _log.i('BatteryNotificationService: stopped');
  }

  void dispose() => stop();

  /// Reset alert history (e.g. after device reconnect).
  void resetAlerts() => _lastAlertLevel.clear();

  // ── Internal ───────────────────────────────────────────────────

  void _check(BluetoothHeadphone? device) {
    if (!_enabled || device == null || !device.isConnected) return;

    final battery = device.batteryMinimum;
    if (battery < 0) return; // unknown

    final level = _classifyLevel(battery);
    if (level == BatteryAlertLevel.none) return;

    final previous = _lastAlertLevel[device.address];
    if (previous == level) return; // already alerted at this level

    _lastAlertLevel[device.address] = level;
    _log.i('BatteryNotificationService: ${device.name} battery $battery% → $level');
    onAlert?.call(device, level, battery);
  }

  BatteryAlertLevel _classifyLevel(int percentage) {
    if (percentage <= urgentThreshold) return BatteryAlertLevel.urgent;
    if (percentage <= criticalThreshold) return BatteryAlertLevel.critical;
    if (percentage <= warningThreshold) return BatteryAlertLevel.warning;
    return BatteryAlertLevel.none;
  }
}
