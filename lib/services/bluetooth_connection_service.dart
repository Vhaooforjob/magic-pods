import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/bluetooth_device.dart';

/// Handles explicit Connect/Disconnect requests from the app UI.
///
/// Under the hood on Windows, this requires calling Bluetooth APIs
/// (e.g. `BluetoothSetServiceState`) to enable/disable the Audio Sink profile,
/// or using a PowerShell script fallback.
class BluetoothConnectionService {
  BluetoothConnectionService({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/bluetooth_control');

  /// Connect to the specified device.
  Future<bool> connect(BluetoothHeadphone device) async {
    _log.i('BluetoothConnectionService: attempting to connect to ${device.name} (${device.address})');
    try {
      final success = await _channel.invokeMethod<bool>('connectDevice', {'address': device.address});
      return success ?? false;
    } on MissingPluginException {
      _log.w('BluetoothConnectionService: native plugin missing, returning mock success');
      return true; // Mock success
    } catch (e) {
      _log.e('BluetoothConnectionService: connect failed', error: e);
      return false;
    }
  }

  /// Disconnect the specified device.
  Future<bool> disconnect(BluetoothHeadphone device) async {
    _log.i('BluetoothConnectionService: attempting to disconnect ${device.name} (${device.address})');
    try {
      final success = await _channel.invokeMethod<bool>('disconnectDevice', {'address': device.address});
      return success ?? false;
    } on MissingPluginException {
      _log.w('BluetoothConnectionService: native plugin missing, returning mock success');
      return true; // Mock success
    } catch (e) {
      _log.e('BluetoothConnectionService: disconnect failed', error: e);
      return false;
    }
  }
}
