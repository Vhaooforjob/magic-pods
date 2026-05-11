import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class MagicPodsApp extends ConsumerStatefulWidget {
  const MagicPodsApp({super.key});

  @override
  ConsumerState<MagicPodsApp> createState() => _MagicPodsAppState();
}

class _MagicPodsAppState extends ConsumerState<MagicPodsApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide(); // Minimize to tray
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicPods',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
