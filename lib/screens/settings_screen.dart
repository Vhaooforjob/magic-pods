import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSectionHeader(context, 'Features'),
          SwitchListTile(
            title: const Text('Ear Detection'),
            subtitle: const Text('Pause media when earbuds are removed'),
            value: settings.earDetectionEnabled,
            onChanged: settingsNotifier.setEarDetection,
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Auto Switch Audio Output'),
            subtitle: const Text('Switch output when headphones connect'),
            value: settings.autoSwitchAudioOutput,
            onChanged: settingsNotifier.setAutoSwitchAudio,
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Low Battery Notifications'),
            subtitle: const Text('Alert when battery is critically low'),
            value: settings.lowBatteryNotification,
            onChanged: settingsNotifier.setLowBatteryNotification,
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('VoiceOver'),
            subtitle: const Text('Read system notifications aloud'),
            value: settings.voiceOverEnabled,
            onChanged: settingsNotifier.setVoiceOver,
            activeColor: AppColors.primary,
          ),
          
          const Divider(height: AppSpacing.xxl),
          
          _buildSectionHeader(context, 'Hotkeys'),
          ListTile(
            title: const Text('Connect / Disconnect'),
            trailing: Text(
              settings.hotkeyConnect,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // TODO: Open hotkey editor
            },
          ),
          ListTile(
            title: const Text('Switch Audio Output'),
            trailing: Text(
              settings.hotkeySwitchOutput,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Show Battery Popup'),
            trailing: Text(
              settings.hotkeyShowBattery,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(height: AppSpacing.xxl),
          
          _buildSectionHeader(context, 'System'),
          SwitchListTile(
            title: const Text('Start with Windows'),
            value: settings.startWithWindows,
            onChanged: (val) {
              settingsNotifier.updateSettings(settings.copyWith(startWithWindows: val));
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Minimize to Tray'),
            value: settings.minimizeToTray,
            onChanged: (val) {
              settingsNotifier.updateSettings(settings.copyWith(minimizeToTray: val));
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.md),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
