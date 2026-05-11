import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/device_card.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final activeDeviceAsync = ref.watch(activeDeviceStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient / Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                boxShadow: AppShadows.glow(AppColors.primary, intensity: 0.4),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MagicPods',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => ref.read(bleScannerProvider).refreshScan(),
                            tooltip: 'Refresh scan',
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Manage your Apple and Beats devices on Windows',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Device List
                  Expanded(
                    child: devicesAsync.when(
                      data: (devices) {
                        if (devices.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bluetooth_searching, size: 64, color: AppColors.textTertiary),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Scanning for devices...',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final activeDevice = activeDeviceAsync.valueOrNull;

                        return ListView.separated(
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            final isActive = activeDevice?.address == device.address;

                            return DeviceCard(
                              device: device,
                              isActive: isActive,
                              onTap: () async {
                                ref.read(deviceManagerProvider).setActiveDevice(device.address);
                                
                                // 1. Ensure Bluetooth is connected
                                debugPrint('Ensuring Bluetooth connection for: ${device.name}');
                                await ref.read(bluetoothConnectionServiceProvider).connect(device);
                                
                                // 2. Wait for Windows to register audio endpoints
                                await Future.delayed(const Duration(seconds: 1));
                                
                                // 3. Refresh audio list
                                await ref.read(audioServiceProvider).refreshDevices();
                                final audioDevices = ref.read(audioServiceProvider).devices;
                                
                                debugPrint('Switching Audio: Target Device = ${device.name}');
                                debugPrint('Available Audio Devices: ${audioDevices.map((d) => d.name).toList()}');

                                try {
                                  // Clean name helper: remove "(", ")", "Stereo", "Headphones" etc.
                                  String clean(String s) => s.toLowerCase()
                                      .replaceAll(RegExp(r'\(.*?\)|stereo|headphones|hands-free|ag audio'), '')
                                      .trim();

                                  final targetClean = clean(device.name);
                                  
                                  final matchingAudio = audioDevices.firstWhere(
                                    (d) {
                                      final audioClean = clean(d.name);
                                      return audioClean.contains(targetClean) || 
                                             targetClean.contains(audioClean);
                                    },
                                  );
                                  
                                  debugPrint('Match Found: ${matchingAudio.name}');
                                  await ref.read(audioServiceProvider).setDefaultDevice(matchingAudio.id);
                                } catch (e) {
                                  debugPrint('Audio Switching Error: No matching audio endpoint found for ${device.name}');
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text('Error: $err', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
