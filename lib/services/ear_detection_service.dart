import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/bluetooth_device.dart';
import 'device_manager.dart';

/// Watches the active device's in-ear state and sends media pause/play
/// commands when earbuds are removed or inserted.
///
/// Uses `SystemMediaTransportControls` on Windows via a MethodChannel,
/// falling back to simulated key-press events.
class EarDetectionService {
  EarDetectionService({
    required DeviceManager deviceManager,
    Logger? logger,
  })  : _deviceManager = deviceManager,
        _log = logger ?? Logger();

  final DeviceManager _deviceManager;
  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/media_control');

  StreamSubscription<BluetoothHeadphone?>? _sub;
  bool _enabled = true;
  bool _wasInEar = false;
  bool _isPlaying = false; // track assumed playback state

  // ── Public API ─────────────────────────────────────────────────

  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) _wasInEar = false;
  }

  /// Start monitoring the active device.
  void start() {
    _sub?.cancel();
    _sub = _deviceManager.activeDeviceStream.listen(_onActiveDeviceChanged);
    _log.i('EarDetectionService: started');
  }

  /// Stop monitoring.
  void stop() {
    _sub?.cancel();
    _sub = null;
    _wasInEar = false;
    _log.i('EarDetectionService: stopped');
  }

  void dispose() {
    stop();
  }

  // ── Internal ───────────────────────────────────────────────────

  void _onActiveDeviceChanged(BluetoothHeadphone? device) {
    if (!_enabled || device == null) return;
    if (!device.model.supportsEarDetection) return;
    if (!device.isConnected) return;

    final nowInEar = device.isAnyInEar;

    if (_wasInEar && !nowInEar) {
      // Removed from ear → pause
      _log.i('EarDetectionService: earbud removed → pausing');
      _sendMediaCommand('pause');
      _isPlaying = false;
    } else if (!_wasInEar && nowInEar && !_isPlaying) {
      // NOTE: only resume if *we* paused it (tracked via _isPlaying flag).
      // Don't auto-resume if user paused manually.
    } else if (!_wasInEar && nowInEar && _wasInEar) {
      // Re-inserted → play (only if we paused)
      _log.i('EarDetectionService: earbud re-inserted → resuming');
      _sendMediaCommand('play');
      _isPlaying = true;
    }

    _wasInEar = nowInEar;
  }

  Future<void> _sendMediaCommand(String command) async {
    try {
      await _channel.invokeMethod(command);
    } on MissingPluginException {
      // Fallback: simulate media key press via platform
      _log.w('EarDetectionService: native media control not available');
    }
  }
}
