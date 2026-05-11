import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/bluetooth_device.dart';
import '../theme/app_theme.dart';
import '../widgets/battery_indicator.dart';

/// An iPhone-style popup window that appears when the case lid is opened.
/// It uses a transparent background and a glassmorphism card that slides up.
class PopupWindow extends StatelessWidget {
  const PopupWindow({
    super.key,
    required this.device,
    required this.onClose,
  });

  final BluetoothHeadphone device;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose, // Tap outside to close
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the card itself
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: GlassDecoration.card(borderRadius: AppRadius.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dismiss button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // Illustration Placeholder
                  // In a full implementation, you'd show a 3D asset or image
                  // based on `device.model`.
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Icon(
                        device.model.type == HeadphoneType.overEar
                            ? Icons.headphones
                            : Icons.earbuds,
                        size: 64,
                        color: AppColors.primaryLight,
                      ).animate(onPlay: (controller) => controller.repeat())
                       .shimmer(duration: 2000.ms),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Battery row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BatteryIndicator(
                        percentage: device.batteryLeft,
                        label: 'L',
                        isCharging: device.isLeftCharging,
                        size: 50,
                      ),
                      if (device.model.hasCase)
                        BatteryIndicator(
                          percentage: device.batteryCase,
                          label: 'Case',
                          isCharging: device.isCaseCharging,
                          size: 60, // slightly larger
                        ),
                      BatteryIndicator(
                        percentage: device.batteryRight,
                        label: 'R',
                        isCharging: device.isRightCharging,
                        size: 50,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate()
             .slideY(begin: 1.0, end: 0, curve: Curves.easeOutBack, duration: 500.ms)
             .fadeIn(),
          ),
        ),
      ),
    );
  }
}
