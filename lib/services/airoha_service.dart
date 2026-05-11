import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/bluetooth_device.dart';

/// Features specific to Airoha 1562AE/1562E chips (Fake AirPods).
class AirohaService {
  AirohaService({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/airoha');

  /// Toggle ANC / Transparency mode.
  Future<bool> setNoiseControlMode(BluetoothHeadphone device, NoiseControlMode mode) async {
    if (!device.model.isFake) return false;
    
    _log.i('AirohaService: setting noise control mode to $mode for ${device.name}');
    try {
      final success = await _channel.invokeMethod<bool>('setNoiseControlMode', {
        'address': device.address,
        'mode': mode.index,
      });
      return success ?? false;
    } on MissingPluginException {
      _log.w('AirohaService: native plugin missing');
      return true;
    } catch (e) {
      _log.e('AirohaService: failed to set noise control', error: e);
      return false;
    }
  }

  /// Enable or disable low-latency Gaming Mode.
  Future<bool> setGamingMode(BluetoothHeadphone device, bool enabled) async {
    if (!device.model.isFake) return false;

    _log.i('AirohaService: setting gaming mode to $enabled for ${device.name}');
    try {
      final success = await _channel.invokeMethod<bool>('setGamingMode', {
        'address': device.address,
        'enabled': enabled,
      });
      return success ?? false;
    } on MissingPluginException {
      _log.w('AirohaService: native plugin missing');
      return true;
    } catch (e) {
      _log.e('AirohaService: failed to set gaming mode', error: e);
      return false;
    }
  }

  /// Enable or disable Wind Noise Canceling.
  Future<bool> setWindNoiseCanceling(BluetoothHeadphone device, bool enabled) async {
    if (!device.model.isFake) return false;

    _log.i('AirohaService: setting wind noise canceling to $enabled for ${device.name}');
    try {
      final success = await _channel.invokeMethod<bool>('setWindNoiseCanceling', {
        'address': device.address,
        'enabled': enabled,
      });
      return success ?? false;
    } on MissingPluginException {
      _log.w('AirohaService: native plugin missing');
      return true;
    } catch (e) {
      _log.e('AirohaService: failed to set wind noise canceling', error: e);
      return false;
    }
  }
}
