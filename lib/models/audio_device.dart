import 'package:equatable/equatable.dart';

/// Represents a Windows audio playback or recording device.
class AudioDevice extends Equatable {
  const AudioDevice({
    required this.id,
    required this.name,
    required this.isDefault,
    this.volume = 1.0,
    this.isMuted = false,
    this.type = AudioDeviceType.output,
  });

  /// Unique system identifier (endpoint ID).
  final String id;

  /// Human-readable name (e.g. "Speakers (Realtek Audio)").
  final String name;

  /// Whether this is the current default device.
  final bool isDefault;

  /// Master volume 0.0 – 1.0.
  final double volume;

  /// Whether the device is muted.
  final bool isMuted;

  /// Output (playback) or input (recording).
  final AudioDeviceType type;

  /// Volume as an integer percentage (0–100).
  int get volumePercent => (volume * 100).round();

  /// Friendly short name (strips manufacturer prefix if possible).
  String get shortName {
    // "Speakers (Realtek High Def)" → "Speakers"
    final idx = name.indexOf('(');
    if (idx > 1) return name.substring(0, idx).trim();
    return name;
  }

  AudioDevice copyWith({
    String? id,
    String? name,
    bool? isDefault,
    double? volume,
    bool? isMuted,
    AudioDeviceType? type,
  }) {
    return AudioDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, name, isDefault, volume, isMuted, type];
}

enum AudioDeviceType { output, input }
