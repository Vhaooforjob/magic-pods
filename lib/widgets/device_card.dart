import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/bluetooth_device.dart';
import '../theme/app_theme.dart';
import 'battery_indicator.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.isActive,
    this.onTap,
  });

  final BluetoothHeadphone device;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: GlassDecoration.card(
          color: isActive 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : AppColors.glassBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    device.model.type == HeadphoneType.overEar
                        ? Icons.headphones
                        : Icons.earbuds,
                    color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: device.isConnected ? AppColors.success : AppColors.textTertiary,
                            ),
                          ).animate(target: device.isConnected ? 1 : 0)
                           .tint(color: AppColors.success)
                           .then()
                           .shimmer(duration: 2000.ms),
                          const SizedBox(width: 6),
                          Text(
                            device.isConnected ? 'Connected' : 'Disconnected',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: device.isConnected 
                                      ? AppColors.textSecondary 
                                      : AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(Icons.check_circle, color: AppColors.primary)
                      .animate()
                      .scale(curve: Curves.easeOutBack, duration: 400.ms),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Battery Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BatteryIndicator(
                  percentage: device.batteryLeft,
                  label: 'Left',
                  isCharging: device.isLeftCharging,
                ),
                BatteryIndicator(
                  percentage: device.batteryRight,
                  label: 'Right',
                  isCharging: device.isRightCharging,
                ),
                if (device.model.hasCase)
                  BatteryIndicator(
                    percentage: device.batteryCase,
                    label: 'Case',
                    isCharging: device.isCaseCharging,
                  ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
