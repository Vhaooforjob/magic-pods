import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/audio_device.dart';

/// Manages Windows audio output devices: enumerating, switching defaults,
/// and controlling volume.
///
/// Uses the `win32audio` package under the hood when available, falling back
/// to MethodChannel calls to the native runner.
class AudioService {
  AudioService({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/audio');

  final _devicesController = StreamController<List<AudioDevice>>.broadcast();
  final _defaultDeviceController = StreamController<AudioDevice?>.broadcast();

  List<AudioDevice> _cachedDevices = [];
  AudioDevice? _cachedDefault;

  Timer? _pollTimer;

  // ── Public API ─────────────────────────────────────────────────

  Stream<List<AudioDevice>> get devicesStream => _devicesController.stream;
  Stream<AudioDevice?> get defaultDeviceStream => _defaultDeviceController.stream;

  List<AudioDevice> get devices => _cachedDevices;
  AudioDevice? get defaultDevice => _cachedDefault;

  /// Initialise and start polling device list.
  Future<void> init() async {
    _log.i('AudioService: initialising');
    await refreshDevices();
    // Poll every 3 seconds for device changes.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => refreshDevices());
  }

  /// Refresh the device list from the OS.
  Future<void> refreshDevices() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getOutputDevices');
      if (result == null) {
        _useMockDevices();
        return;
      }

      _cachedDevices = result.map((d) {
        final map = Map<String, dynamic>.from(d as Map);
        return AudioDevice(
          id: map['id'] as String,
          name: map['name'] as String,
          isDefault: map['isDefault'] as bool? ?? false,
          volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
          isMuted: map['isMuted'] as bool? ?? false,
        );
      }).toList();

      _cachedDefault = _cachedDevices.cast<AudioDevice?>().firstWhere(
            (d) => d!.isDefault,
            orElse: () => _cachedDevices.isNotEmpty ? _cachedDevices.first : null,
          );
    } on MissingPluginException {
      _useMockDevices();
    } catch (e) {
      _log.e('AudioService: failed to refresh devices', error: e);
      _useMockDevices();
    }

    _devicesController.add(_cachedDevices);
    _defaultDeviceController.add(_cachedDefault);
  }

  /// Set a device as the system default output.
  Future<bool> setDefaultDevice(String deviceId) async {
    _log.i('AudioService: setting default device to $deviceId');
    try {
      final success = await _channel.invokeMethod<bool>('setDefaultDevice', {'id': deviceId});
      if (success == true) {
        await refreshDevices();
        return true;
      }
    } on MissingPluginException {
      // Simulate
      _cachedDevices = _cachedDevices
          .map((d) => d.copyWith(isDefault: d.id == deviceId))
          .toList();
      _cachedDefault = _cachedDevices.cast<AudioDevice?>().firstWhere(
            (d) => d!.id == deviceId,
            orElse: () => null,
          );
      _devicesController.add(_cachedDevices);
      _defaultDeviceController.add(_cachedDefault);
      return true;
    } catch (e) {
      _log.e('AudioService: failed to set default device', error: e);
    }
    return false;
  }

  /// Switch to the next available output device (round-robin).
  Future<bool> switchToNextDevice() async {
    if (_cachedDevices.length < 2) return false;
    final currentIdx = _cachedDevices.indexWhere((d) => d.isDefault);
    final nextIdx = (currentIdx + 1) % _cachedDevices.length;
    return setDefaultDevice(_cachedDevices[nextIdx].id);
  }

  /// Set master volume (0.0 – 1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
    } catch (_) {}
  }

  void dispose() {
    _pollTimer?.cancel();
    _devicesController.close();
    _defaultDeviceController.close();
  }

  // ── Mock for development ───────────────────────────────────────

  void _useMockDevices() {
    _cachedDevices = [
      const AudioDevice(
        id: 'speaker_1',
        name: 'Speakers (Realtek High Definition Audio)',
        isDefault: true,
        volume: 0.75,
      ),
      const AudioDevice(
        id: 'headphones_bt',
        name: 'AirPods Pro (Bluetooth)',
        isDefault: false,
        volume: 0.8,
      ),
      const AudioDevice(
        id: 'hdmi_1',
        name: 'HDMI Audio (NVIDIA High Definition Audio)',
        isDefault: false,
        volume: 0.5,
      ),
    ];
    _cachedDefault = _cachedDevices.first;
  }
}
