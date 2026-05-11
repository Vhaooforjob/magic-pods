import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/bluetooth_device.dart';
import '../native/apple_continuity_parser.dart';

/// Service that scans for BLE advertisements from Apple/Beats headphones
/// and parses their battery / status data.
///
/// On Windows this uses a MethodChannel to the native C++ runner which calls
/// `Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher`.
///
/// A built-in **simulation mode** is available for development when no
/// native implementation is compiled (returns mock data).
class BleScanner {
  BleScanner({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;
  static const _channel = MethodChannel('com.magicpods/ble_scanner');

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Timer? _simulationTimer;
  bool _useSimulation = true; // flip when native layer is ready

  final _controller = StreamController<BluetoothHeadphone>.broadcast();

  /// Stream of discovered / updated headphones.
  Stream<BluetoothHeadphone> get deviceStream => _controller.stream;

  // ── Public API ─────────────────────────────────────────────────

  /// Start scanning for BLE advertisements.
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _log.i('BleScanner: starting scan');

    try {
      await _channel.invokeMethod('startScan');
      _useSimulation = false;
      _channel.setMethodCallHandler(_handleNativeCallback);
      _log.i('BleScanner: native scan started');
    } on MissingPluginException {
      _log.w('BleScanner: native plugin not available, using simulation');
      _useSimulation = true;
      _startSimulation();
    }
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;
    _log.i('BleScanner: stopping scan');

    if (_useSimulation) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
    } else {
      try {
        await _channel.invokeMethod('stopScan');
      } catch (e) {
        _log.e('BleScanner: failed to stop native scan', error: e);
      }
    }
  }

  /// Release resources.
  void dispose() {
    stopScan();
    _controller.close();
  }

  // ── Native callback handler ────────────────────────────────────

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onAdvertisementReceived') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final address = args['address'] as String;
      final name = args['name'] as String? ?? '';
      final rssi = args['rssi'] as int? ?? 0;
      final rawData = args['manufacturerData'] as Uint8List?;

      if (rawData == null || rawData.isEmpty) return;

      final parsed = AppleContinuityParser.parse(rawData);
      if (parsed == null) return;

      final device = BluetoothHeadphone(
        address: address,
        name: name.isEmpty ? parsed.model.shortName : name,
        model: parsed.model,
        batteryLeft: parsed.batteryLeft,
        batteryRight: parsed.batteryRight,
        batteryCase: parsed.batteryCase,
        isLeftCharging: parsed.isLeftCharging,
        isRightCharging: parsed.isRightCharging,
        isCaseCharging: parsed.isCaseCharging,
        isLeftInEar: parsed.isLeftInEar,
        isRightInEar: parsed.isRightInEar,
        isLidOpen: parsed.isLidOpen,
        isConnected: true,
        rssi: rssi,
        lastSeen: DateTime.now(),
      );
      _controller.add(device);
    }
  }

  // ── Simulation for development ─────────────────────────────────

  void _startSimulation() {
    final rng = Random();
    int tick = 0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isScanning) return;
      tick++;

      // Simulate battery drain
      final baseBattery = max(5, 85 - (tick ~/ 10));
      final isEarL = tick % 8 != 0; // remove every 8th tick
      final isEarR = tick % 12 != 0;

      final device = BluetoothHeadphone(
        address: 'AA:BB:CC:DD:EE:FF',
        name: 'AirPods Pro',
        model: HeadphoneModel.airpodsPro2,
        batteryLeft: baseBattery + rng.nextInt(10),
        batteryRight: baseBattery + rng.nextInt(10) - 3,
        batteryCase: max(0, baseBattery - 10 + rng.nextInt(5)),
        isLeftCharging: false,
        isRightCharging: false,
        isCaseCharging: tick % 20 < 5,
        isLeftInEar: isEarL,
        isRightInEar: isEarR,
        isLidOpen: tick % 15 < 3,
        isConnected: true,
        rssi: -50 - rng.nextInt(30),
        lastSeen: DateTime.now(),
      );
      _controller.add(device);

      // Optionally add a second simulated device
      if (tick > 5 && tick % 4 == 0) {
        final beats = BluetoothHeadphone(
          address: '11:22:33:44:55:66',
          name: 'Beats Fit Pro',
          model: HeadphoneModel.beatsFitPro,
          batteryLeft: 60 + rng.nextInt(20),
          batteryRight: 55 + rng.nextInt(20),
          batteryCase: 40 + rng.nextInt(30),
          isLeftInEar: true,
          isRightInEar: true,
          isConnected: true,
          rssi: -60 - rng.nextInt(20),
          lastSeen: DateTime.now(),
        );
        _controller.add(beats);
      }
    });
  }
}
