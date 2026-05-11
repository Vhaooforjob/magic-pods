import 'package:equatable/equatable.dart';

// ══════════════════════════════════════════════════════════════════════
// Headphone model enumeration – covers AirPods, Beats, and clone chips.
// ══════════════════════════════════════════════════════════════════════

/// Known headphone models that the app can recognise from BLE adverts.
enum HeadphoneModel {
  airpods1('AirPods', 'AirPods (1st Generation)', HeadphoneType.inEar),
  airpods2('AirPods', 'AirPods (2nd Generation)', HeadphoneType.inEar),
  airpods3('AirPods', 'AirPods (3rd Generation)', HeadphoneType.inEar),
  airpodsPro('AirPods Pro', 'AirPods Pro', HeadphoneType.inEar),
  airpodsPro2('AirPods Pro 2', 'AirPods Pro (2nd Generation)', HeadphoneType.inEar),
  airpodsMax('AirPods Max', 'AirPods Max', HeadphoneType.overEar),
  airpodsMax2024('AirPods Max', 'AirPods Max (2024)', HeadphoneType.overEar),
  airpodsMax2026('AirPods Max 2', 'AirPods Max 2 (2026)', HeadphoneType.overEar),
  airpods4('AirPods 4', 'AirPods (4th Generation)', HeadphoneType.inEar),
  airpods4Anc('AirPods 4 ANC', 'AirPods (4th Gen ANC)', HeadphoneType.inEar),
  beatsSolo3('Beats Solo3', 'Beats Solo3 Wireless', HeadphoneType.onEar),
  beatsStudio3('Beats Studio3', 'Beats Studio3 Wireless', HeadphoneType.overEar),
  beatsFlex('Beats Flex', 'Beats Flex', HeadphoneType.neckband),
  beatsFitPro('Beats Fit Pro', 'Beats Fit Pro', HeadphoneType.inEar),
  beatsStudioBuds('Beats Studio Buds', 'Beats Studio Buds', HeadphoneType.inEar),
  beatsStudioBudsPlus('Beats Studio Buds+', 'Beats Studio Buds+', HeadphoneType.inEar),
  beatsStudioPro('Beats Studio Pro', 'Beats Studio Pro', HeadphoneType.overEar),
  beatsSolobuds('Beats Solo Buds', 'Beats Solo Buds', HeadphoneType.inEar),
  powerBeatsPro('Powerbeats Pro', 'Powerbeats Pro', HeadphoneType.inEar),
  powerBeatsPro2('Powerbeats Pro 2', 'Powerbeats Pro 2', HeadphoneType.inEar),
  fakeAirpodsPro('Fake AirPods Pro', 'Airoha 1562AE', HeadphoneType.inEar),
  fakeAirpodsPro2('Fake AirPods Pro 2', 'Airoha 1562AE v2', HeadphoneType.inEar),
  fakeAirpods3('Fake AirPods 3', 'Airoha 1562E', HeadphoneType.inEar),
  unknown('Unknown', 'Unknown Headphones', HeadphoneType.inEar);

  const HeadphoneModel(this.shortName, this.fullName, this.type);

  final String shortName;
  final String fullName;
  final HeadphoneType type;

  /// Whether this model supports ear detection via Apple Continuity.
  bool get supportsEarDetection {
    switch (this) {
      case airpods1:
      case airpods2:
      case airpods3:
      case airpods4:
      case airpods4Anc:
      case airpodsPro:
      case airpodsPro2:
      case airpodsMax:
      case airpodsMax2024:
      case airpodsMax2026:
      case powerBeatsPro:
      case powerBeatsPro2:
      case beatsFitPro:
      case fakeAirpodsPro:
      case fakeAirpodsPro2:
      case fakeAirpods3:
        return true;
      default:
        return false;
    }
  }

  /// Whether this model supports ANC / Transparency toggle.
  bool get supportsNoiseControl {
    switch (this) {
      case airpodsPro:
      case airpodsPro2:
      case airpods4Anc:
      case airpodsMax:
      case airpodsMax2024:
      case airpodsMax2026:
      case beatsFitPro:
      case beatsStudioBuds:
      case beatsStudioBudsPlus:
      case beatsStudioPro:
      case fakeAirpodsPro:
      case fakeAirpodsPro2:
        return true;
      default:
        return false;
    }
  }

  /// Whether the device has a separate case with its own battery.
  bool get hasCase {
    switch (type) {
      case HeadphoneType.inEar:
        return true;
      case HeadphoneType.overEar:
      case HeadphoneType.onEar:
      case HeadphoneType.neckband:
        return false;
    }
  }

  /// Whether this is a fake/clone device (Airoha chip).
  bool get isFake {
    switch (this) {
      case fakeAirpodsPro:
      case fakeAirpodsPro2:
      case fakeAirpods3:
        return true;
      default:
        return false;
    }
  }
}

enum HeadphoneType { inEar, onEar, overEar, neckband }

// ══════════════════════════════════════════════════════════════════════
// Bluetooth headphone data model
// ══════════════════════════════════════════════════════════════════════

/// Noise-control mode for devices that support it.
enum NoiseControlMode { off, noiseCancellation, transparency, adaptive }

/// Immutable snapshot of a detected Bluetooth headphone.
class BluetoothHeadphone extends Equatable {
  const BluetoothHeadphone({
    required this.address,
    required this.name,
    required this.model,
    this.batteryLeft = -1,
    this.batteryRight = -1,
    this.batteryCase = -1,
    this.isLeftCharging = false,
    this.isRightCharging = false,
    this.isCaseCharging = false,
    this.isLeftInEar = false,
    this.isRightInEar = false,
    this.isLidOpen = false,
    this.isConnected = false,
    this.noiseControlMode = NoiseControlMode.off,
    this.firmwareVersion,
    this.rssi = 0,
    required this.lastSeen,
  });

  final String address;
  final String name;
  final HeadphoneModel model;

  /// Battery percentage 0-100. A value of -1 means unknown.
  final int batteryLeft;
  final int batteryRight;
  final int batteryCase;

  final bool isLeftCharging;
  final bool isRightCharging;
  final bool isCaseCharging;

  final bool isLeftInEar;
  final bool isRightInEar;

  final bool isLidOpen;
  final bool isConnected;

  final NoiseControlMode noiseControlMode;
  final String? firmwareVersion;
  final int rssi;
  final DateTime lastSeen;

  // ── Computed helpers ────────────────────────────────────────────

  /// The average battery percentage of left + right earbuds.
  /// Returns the single known value when only one is available.
  int get batteryAverage {
    if (batteryLeft >= 0 && batteryRight >= 0) {
      return ((batteryLeft + batteryRight) / 2).round();
    }
    if (batteryLeft >= 0) return batteryLeft;
    if (batteryRight >= 0) return batteryRight;
    return -1;
  }

  /// Overall minimum battery across all components.
  int get batteryMinimum {
    final values = <int>[
      if (batteryLeft >= 0) batteryLeft,
      if (batteryRight >= 0) batteryRight,
      if (batteryCase >= 0 && model.hasCase) batteryCase,
    ];
    if (values.isEmpty) return -1;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// `true` when any component is charging.
  bool get isAnyCharging => isLeftCharging || isRightCharging || isCaseCharging;

  /// `true` when both earbuds are in-ear.
  bool get isBothInEar => isLeftInEar && isRightInEar;

  /// `true` when at least one earbud is in-ear.
  bool get isAnyInEar => isLeftInEar || isRightInEar;

  /// `true` when battery is critically low (< 10 %).
  bool get isBatteryCritical => batteryMinimum >= 0 && batteryMinimum < 10;

  /// `true` when battery is low (< 20 %).
  bool get isBatteryLow => batteryMinimum >= 0 && batteryMinimum < 20;

  // ── Copy ────────────────────────────────────────────────────────

  BluetoothHeadphone copyWith({
    String? address,
    String? name,
    HeadphoneModel? model,
    int? batteryLeft,
    int? batteryRight,
    int? batteryCase,
    bool? isLeftCharging,
    bool? isRightCharging,
    bool? isCaseCharging,
    bool? isLeftInEar,
    bool? isRightInEar,
    bool? isLidOpen,
    bool? isConnected,
    NoiseControlMode? noiseControlMode,
    String? firmwareVersion,
    int? rssi,
    DateTime? lastSeen,
  }) {
    return BluetoothHeadphone(
      address: address ?? this.address,
      name: name ?? this.name,
      model: model ?? this.model,
      batteryLeft: batteryLeft ?? this.batteryLeft,
      batteryRight: batteryRight ?? this.batteryRight,
      batteryCase: batteryCase ?? this.batteryCase,
      isLeftCharging: isLeftCharging ?? this.isLeftCharging,
      isRightCharging: isRightCharging ?? this.isRightCharging,
      isCaseCharging: isCaseCharging ?? this.isCaseCharging,
      isLeftInEar: isLeftInEar ?? this.isLeftInEar,
      isRightInEar: isRightInEar ?? this.isRightInEar,
      isLidOpen: isLidOpen ?? this.isLidOpen,
      isConnected: isConnected ?? this.isConnected,
      noiseControlMode: noiseControlMode ?? this.noiseControlMode,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        address,
        name,
        model,
        batteryLeft,
        batteryRight,
        batteryCase,
        isLeftCharging,
        isRightCharging,
        isCaseCharging,
        isLeftInEar,
        isRightInEar,
        isLidOpen,
        isConnected,
        noiseControlMode,
        firmwareVersion,
        rssi,
        lastSeen,
      ];

  @override
  String toString() =>
      'BluetoothHeadphone(${model.shortName}, $name, L:$batteryLeft% R:$batteryRight% C:$batteryCase%)';
}
