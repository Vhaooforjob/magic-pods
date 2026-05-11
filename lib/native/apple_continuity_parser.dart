import 'dart:typed_data';
import '../models/bluetooth_device.dart';

/// Parses Apple Continuity Protocol data from BLE advertisement
/// manufacturer-specific data.
///
/// Reference: Reverse-engineered from OpenPods / AirPodsDesktop projects.
/// Apple Company ID = 0x004C.  Continuity type 0x07 = Proximity Pairing.
///
/// Data layout (after Company ID):
/// ```
/// Byte 0:   Continuity type (0x07)
/// Byte 1:   Length
/// Byte 2:   Device model (high nibble = prefix)
/// Byte 3:   Device model (low byte)
/// Byte 4:   Status byte
/// Byte 5:   Battery left  (low nibble 0-10) | charging flag bit 4
/// Byte 6:   Battery right (low nibble 0-10) | charging flag bit 4
/// Byte 7:   Battery case  (low nibble 0-10) | charging flag bit 4
/// Byte 8:   Lid open/close + color
/// ...
/// ```
class AppleContinuityParser {
  AppleContinuityParser._();

  /// Apple's registered Bluetooth Company Identifier.
  static const int appleCompanyId = 0x004C;

  /// Continuity type for Proximity Pairing messages.
  static const int proximityPairingType = 0x07;

  /// Try to parse a manufacturer-specific data blob.
  /// Returns `null` when the data is not an Apple Continuity advert
  /// or cannot be decoded.
  static ParsedAppleData? parse(Uint8List rawData) {
    if (rawData.length < 10) return null;

    // Byte 0-1: Company ID (little-endian). Already filtered upstream
    // when we use the BLE watcher, but double-check here.
    final companyId = rawData[0] | (rawData[1] << 8);
    if (companyId != appleCompanyId) return null;

    // Look for the Proximity Pairing sub-TLV inside the payload.
    int offset = 2;
    while (offset < rawData.length - 2) {
      final type = rawData[offset];
      final length = rawData[offset + 1];

      if (type == proximityPairingType && length >= 0x19 && offset + length + 2 <= rawData.length) {
        return _parseProximityPairing(rawData, offset + 2);
      }
      offset += 2 + length;
    }
    return null;
  }

  static ParsedAppleData? _parseProximityPairing(Uint8List data, int start) {
    if (start + 25 > data.length) return null;

    // Bytes 0-1 relative to `start`: device model (16-bit).
    final modelHigh = data[start];
    final modelLow = data[start + 1];
    final modelCode = (modelHigh << 8) | modelLow;

    // Byte 2: UPI (status flags).
    final status = data[start + 2];

    // Byte 5-7: Battery values.  Each nibble pair contains:
    //   bits 0-3 = level (0-10, multiply by 10 for %)
    //   bit 4    = charging flag
    // The high nibble of byte 5 is left, low nibble is right.
    // Byte 6 high nibble is case.
    // (layout varies slightly; use the most common interpretation)
    final batteryByte1 = data[start + 5];
    final batteryByte2 = data[start + 6];

    int rawLeft = (batteryByte1 >> 4) & 0x0F;
    int rawRight = batteryByte1 & 0x0F;
    int rawCase = (batteryByte2 >> 4) & 0x0F;

    final chargingByte = data[start + 7];
    bool isLeftCharging = (chargingByte & 0x01) != 0;
    bool isRightCharging = (chargingByte & 0x02) != 0;
    bool isCaseCharging = (chargingByte & 0x04) != 0;

    // A raw value of 15 (0xF) means "disconnected / unknown".
    int batteryLeft = rawLeft == 15 ? -1 : rawLeft * 10;
    int batteryRight = rawRight == 15 ? -1 : rawRight * 10;
    int batteryCase = rawCase == 15 ? -1 : rawCase * 10;

    // Status nibbles for ear detection.
    // Bit 1 of status → primary in-ear, Bit 3 → secondary in-ear.
    bool primaryInEar = (status & 0x02) != 0;
    bool secondaryInEar = (status & 0x08) != 0;
    // Bit 4 → both in case / lid open.
    bool lidOpen = (status & 0x04) != 0;

    // Detect whether left/right are flipped (common in Apple protocol).
    // Bit 5 of status indicates the "flipped" flag.
    bool flipped = (status & 0x20) != 0;

    bool isLeftInEar;
    bool isRightInEar;
    if (flipped) {
      isLeftInEar = secondaryInEar;
      isRightInEar = primaryInEar;
      // Also swap battery when flipped.
      final tmpBat = batteryLeft;
      batteryLeft = batteryRight;
      batteryRight = tmpBat;
      final tmpChg = isLeftCharging;
      isLeftCharging = isRightCharging;
      isRightCharging = tmpChg;
    } else {
      isLeftInEar = primaryInEar;
      isRightInEar = secondaryInEar;
    }

    final model = _modelFromCode(modelCode);

    return ParsedAppleData(
      modelCode: modelCode,
      model: model,
      batteryLeft: batteryLeft,
      batteryRight: batteryRight,
      batteryCase: batteryCase,
      isLeftCharging: isLeftCharging,
      isRightCharging: isRightCharging,
      isCaseCharging: isCaseCharging,
      isLeftInEar: isLeftInEar,
      isRightInEar: isRightInEar,
      isLidOpen: lidOpen,
      rawStatus: status,
    );
  }

  /// Map a 16-bit model code to our [HeadphoneModel] enum.
  static HeadphoneModel _modelFromCode(int code) {
    // Known codes (from OpenPods & community reverse-engineering).
    switch (code) {
      case 0x2002:
        return HeadphoneModel.airpods1;
      case 0x200F:
        return HeadphoneModel.airpods2;
      case 0x2013:
        return HeadphoneModel.airpods3;
      case 0x200E:
        return HeadphoneModel.airpodsPro;
      case 0x2014:
        return HeadphoneModel.airpodsPro2;
      case 0x200A:
        return HeadphoneModel.airpodsMax;
      case 0x2024:
        return HeadphoneModel.airpodsMax2024;
      case 0x2026:
        return HeadphoneModel.airpodsMax2026;
      case 0x2029:
        return HeadphoneModel.airpods4;
      case 0x202A:
        return HeadphoneModel.airpods4Anc;
      case 0x2009:
        return HeadphoneModel.beatsSolo3;
      case 0x2006:
        return HeadphoneModel.beatsStudio3;
      case 0x2010:
        return HeadphoneModel.beatsFlex;
      case 0x2012:
        return HeadphoneModel.beatsFitPro;
      case 0x2011:
        return HeadphoneModel.beatsStudioBuds;
      case 0x2016:
        return HeadphoneModel.beatsStudioBudsPlus;
      case 0x2017:
        return HeadphoneModel.beatsStudioPro;
      case 0x201B:
        return HeadphoneModel.beatsSolobuds;
      case 0x200B:
        return HeadphoneModel.powerBeatsPro;
      case 0x2020:
        return HeadphoneModel.powerBeatsPro2;
      default:
        // Airoha fakes often reuse Apple model codes; flag them via
        // a separate heuristic in the BLE scanner service.
        return HeadphoneModel.unknown;
    }
  }
}

/// Parsed result of an Apple Continuity Proximity Pairing advertisement.
class ParsedAppleData {
  const ParsedAppleData({
    required this.modelCode,
    required this.model,
    required this.batteryLeft,
    required this.batteryRight,
    required this.batteryCase,
    required this.isLeftCharging,
    required this.isRightCharging,
    required this.isCaseCharging,
    required this.isLeftInEar,
    required this.isRightInEar,
    required this.isLidOpen,
    required this.rawStatus,
  });

  final int modelCode;
  final HeadphoneModel model;
  final int batteryLeft;
  final int batteryRight;
  final int batteryCase;
  final bool isLeftCharging;
  final bool isRightCharging;
  final bool isCaseCharging;
  final bool isLeftInEar;
  final bool isRightInEar;
  final bool isLidOpen;
  final int rawStatus;
}
