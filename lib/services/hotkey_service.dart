import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import 'audio_service.dart';
import 'device_manager.dart';

class HotkeyService {
  HotkeyService({
    required DeviceManager deviceManager,
    required AudioService audioService,
    Logger? logger,
  })  : _deviceManager = deviceManager,
        _audioService = audioService,
        _log = logger ?? Logger();

  final DeviceManager _deviceManager;
  final AudioService _audioService;
  final Logger _log;

  HotKey? _connectHotKey;
  HotKey? _switchOutputHotKey;
  HotKey? _showBatteryHotKey;

  VoidCallback? onShowBatteryPopup;

  Future<void> init(AppSettings settings) async {
    _log.i('HotkeyService: initialising');
    await hotKeyManager.unregisterAll();
    await updateHotkeys(settings);
  }

  Future<void> updateHotkeys(AppSettings settings) async {
    await hotKeyManager.unregisterAll();

    // 1. Connect/Disconnect Hotkey
    if (settings.hotkeyConnect.isNotEmpty) {
      _connectHotKey = _parseHotKey(settings.hotkeyConnect);
      if (_connectHotKey != null) {
        await hotKeyManager.register(
          _connectHotKey!,
          keyDownHandler: (hotKey) {
            _log.i('Hotkey: Connect/Disconnect triggered');
            // Connect/disconnect logic would go here.
            // Requires native Bluetooth APIs to actually force connection.
          },
        );
      }
    }

    // 2. Switch Audio Output Hotkey
    if (settings.hotkeySwitchOutput.isNotEmpty) {
      _switchOutputHotKey = _parseHotKey(settings.hotkeySwitchOutput);
      if (_switchOutputHotKey != null) {
        await hotKeyManager.register(
          _switchOutputHotKey!,
          keyDownHandler: (hotKey) async {
            _log.i('Hotkey: Switch Audio Output triggered');
            await _audioService.switchToNextDevice();
          },
        );
      }
    }

    // 3. Show Battery Hotkey
    if (settings.hotkeyShowBattery.isNotEmpty) {
      _showBatteryHotKey = _parseHotKey(settings.hotkeyShowBattery);
      if (_showBatteryHotKey != null) {
        await hotKeyManager.register(
          _showBatteryHotKey!,
          keyDownHandler: (hotKey) {
            _log.i('Hotkey: Show Battery triggered');
            onShowBatteryPopup?.call();
          },
        );
      }
    }
  }

  HotKey? _parseHotKey(String hotkeyStr) {
    try {
      final parts = hotkeyStr.split('+');
      if (parts.isEmpty) return null;

      final keyStr = parts.last.toUpperCase();
      final modifiersStr = parts.take(parts.length - 1).map((e) => e.toLowerCase()).toList();

      PhysicalKeyboardKey? keyCode;
      // We map the string to a PhysicalKeyboardKey. A robust implementation would use a map.
      // For now, let's do a simple mapping for A, S, B which are used by default.
      switch (keyStr) {
        case 'A': keyCode = PhysicalKeyboardKey.keyA; break;
        case 'S': keyCode = PhysicalKeyboardKey.keyS; break;
        case 'B': keyCode = PhysicalKeyboardKey.keyB; break;
        default:
          _log.w('Unsupported hotkey letter: $keyStr');
          return null;
      }

      List<HotKeyModifier> modifiers = [];
      if (modifiersStr.contains('ctrl')) modifiers.add(HotKeyModifier.control);
      if (modifiersStr.contains('alt')) modifiers.add(HotKeyModifier.alt);
      if (modifiersStr.contains('shift')) modifiers.add(HotKeyModifier.shift);
      if (modifiersStr.contains('meta') || modifiersStr.contains('win')) modifiers.add(HotKeyModifier.meta);

      return HotKey(key: keyCode, modifiers: modifiers);
    } catch (e) {
      _log.e('Failed to parse hotkey: $hotkeyStr', error: e);
      return null;
    }
  }

  void dispose() {
    hotKeyManager.unregisterAll();
  }
}
