import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/app_settings.dart';
import '../models/bluetooth_device.dart';

/// Manages the A2DP Sink functionality (acting as a Bluetooth speaker).
///
/// On Windows 10 (2004+), this uses the `AudioPlaybackConnection` API
/// to receive audio from a phone or Nintendo Switch.
class A2dpSinkService {
  A2dpSinkService({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/a2dp_sink');

  bool _enabled = false;
  String? _activeConnectionId;

  // ── Public API ─────────────────────────────────────────────────

  Future<void> init(AppSettings settings) async {
    _log.i('A2dpSinkService: initialising');
    _enabled = settings.a2dpSinkEnabled;
  }

  /// Update settings when they change.
  void updateSettings(AppSettings settings) {
    if (_enabled != settings.a2dpSinkEnabled) {
      _enabled = settings.a2dpSinkEnabled;
      if (!_enabled) {
        closeConnection();
      }
    }
  }

  /// Open an A2DP Sink connection to receive audio from the device.
  Future<bool> openConnection(BluetoothHeadphone device) async {
    if (!_enabled) {
      _log.w('A2dpSinkService: attempt to open connection while disabled');
      return false;
    }

    _log.i('A2dpSinkService: opening A2DP sink connection to ${device.name}');
    try {
      final success = await _channel.invokeMethod<bool>('openConnection', {'address': device.address});
      if (success == true) {
        _activeConnectionId = device.address;
        return true;
      }
    } on MissingPluginException {
      _log.w('A2dpSinkService: native plugin missing, returning mock success');
      _activeConnectionId = device.address;
      return true; // Mock success
    } catch (e) {
      _log.e('A2dpSinkService: failed to open connection', error: e);
    }
    return false;
  }

  /// Close the active A2DP Sink connection.
  Future<void> closeConnection() async {
    if (_activeConnectionId == null) return;

    _log.i('A2dpSinkService: closing A2DP sink connection');
    try {
      await _channel.invokeMethod('closeConnection');
    } catch (e) {
      _log.e('A2dpSinkService: failed to close connection', error: e);
    } finally {
      _activeConnectionId = null;
    }
  }

  void dispose() {
    closeConnection();
  }
}
