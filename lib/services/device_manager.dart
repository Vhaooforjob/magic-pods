import 'dart:async';
import 'package:logger/logger.dart';
import '../models/bluetooth_device.dart';
import 'ble_scanner_service.dart';

/// Manages the list of known Bluetooth headphones, merges updates from the
/// [BleScanner], and exposes the current state as a stream.
///
/// This is the single-source-of-truth for device state consumed by the UI
/// and by other services (ear-detection, battery-notification, etc.).
class DeviceManager {
  DeviceManager({required BleScanner bleScanner, Logger? logger})
      : _bleScanner = bleScanner,
        _log = logger ?? Logger();

  final BleScanner _bleScanner;
  final Logger _log;

  /// Address → latest device snapshot.
  final Map<String, BluetoothHeadphone> _devices = {};
  String? _activeDeviceAddress;

  StreamSubscription<BluetoothHeadphone>? _scanSub;
  final _devicesController = StreamController<List<BluetoothHeadphone>>.broadcast();
  final _activeDeviceController = StreamController<BluetoothHeadphone?>.broadcast();

  Timer? _pruneTimer;
  static const _pruneInterval = Duration(seconds: 15);
  static const _staleThreshold = Duration(seconds: 30);

  // ── Public streams ─────────────────────────────────────────────

  /// Stream of all currently-known devices (sorted by last seen).
  Stream<List<BluetoothHeadphone>> get devicesStream => _devicesController.stream;

  /// Stream of the currently active (selected) device.
  Stream<BluetoothHeadphone?> get activeDeviceStream => _activeDeviceController.stream;

  /// Synchronous snapshot of all known devices.
  List<BluetoothHeadphone> get devices {
    final list = _devices.values.toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return list;
  }

  /// The currently active device.
  BluetoothHeadphone? get activeDevice =>
      _activeDeviceAddress != null ? _devices[_activeDeviceAddress] : null;

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Initialise manager and start BLE scanning.
  Future<void> init() async {
    _log.i('DeviceManager: initialising');
    _scanSub = _bleScanner.deviceStream.listen(_onDeviceUpdate);
    
    // Emit initial empty state so UI can show "Scanning" instead of "Loading"
    _emitDevices();
    _emitActiveDevice();

    await _bleScanner.startScan();

    // Periodically prune stale devices.
    _pruneTimer = Timer.periodic(_pruneInterval, (_) => _pruneStaleDevices());
  }

  /// Stop scanning and release resources.
  void dispose() {
    _scanSub?.cancel();
    _pruneTimer?.cancel();
    _bleScanner.dispose();
    _devicesController.close();
    _activeDeviceController.close();
  }

  // ── Actions ────────────────────────────────────────────────────

  /// Set a device as the active (primary) device.
  void setActiveDevice(String address) {
    if (!_devices.containsKey(address)) return;
    _activeDeviceAddress = address;
    _emitActiveDevice();
    _log.i('DeviceManager: active device set to $address');
  }

  /// Clear active device selection.
  void clearActiveDevice() {
    _activeDeviceAddress = null;
    _emitActiveDevice();
  }

  // ── Internal ───────────────────────────────────────────────────

  void _onDeviceUpdate(BluetoothHeadphone device) {
    final existing = _devices[device.address];

    // Merge: prefer new battery values but keep old ones if new is unknown.
    final merged = existing != null
        ? device.copyWith(
            batteryLeft: device.batteryLeft >= 0 ? device.batteryLeft : existing.batteryLeft,
            batteryRight: device.batteryRight >= 0 ? device.batteryRight : existing.batteryRight,
            batteryCase: device.batteryCase >= 0 ? device.batteryCase : existing.batteryCase,
            name: device.name.isNotEmpty ? device.name : existing.name,
          )
        : device;

    _devices[device.address] = merged;

    _emitDevices();
    if (device.address == _activeDeviceAddress) {
      _emitActiveDevice();
    }
  }

  void _pruneStaleDevices() {
    final now = DateTime.now();
    final staleAddresses = _devices.entries
        .where((e) => now.difference(e.value.lastSeen) > _staleThreshold)
        .map((e) => e.key)
        .toList();

    if (staleAddresses.isEmpty) return;

    for (final addr in staleAddresses) {
      // Mark as disconnected instead of removing, so UI can still show it.
      _devices[addr] = _devices[addr]!.copyWith(isConnected: false);
    }
    _emitDevices();
    if (staleAddresses.contains(_activeDeviceAddress)) {
      _emitActiveDevice();
    }
  }

  void _emitDevices() {
    if (!_devicesController.isClosed) {
      _devicesController.add(devices);
    }
  }

  void _emitActiveDevice() {
    if (!_activeDeviceController.isClosed) {
      _activeDeviceController.add(activeDevice);
    }
  }
}
