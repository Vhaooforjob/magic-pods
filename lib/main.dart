import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  try {
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Initialize Window Manager
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 700),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });

    // Initialize HotKey Manager
    await hotKeyManager.unregisterAll();

    // Create Riverpod container
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Initialize Core Services
    final deviceManager = container.read(deviceManagerProvider);
    await deviceManager.init();

    final audioService = container.read(audioServiceProvider);
    await audioService.init();

    final trayService = container.read(trayServiceProvider);
    await trayService.init();

    final settings = container.read(settingsProvider);
    
    final hotkeyService = container.read(hotkeyServiceProvider);
    await hotkeyService.init(settings);

    final voiceOverService = container.read(voiceOverServiceProvider);
    await voiceOverService.init(settings);
    
    // Register callbacks for Tray
    trayService.onShowWindow = () => windowManager.show();
    trayService.onQuit = () {
      windowManager.destroy(); // Force exit
    };

    // Run App
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MagicPodsApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stack');
    
    // Fallback UI to show the error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SelectableText('Failed to start MagicPods: $e\n\n$stack'),
        ),
      ),
    ));
  }
}
