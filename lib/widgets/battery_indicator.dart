import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.percentage,
    required this.label,
    this.isCharging = false,
    this.size = 60.0,
  });

  /// 0-100 percentage. -1 means unknown.
  final int percentage;
  final String label;
  final bool isCharging;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isUnknown = percentage < 0;
    final displayPercent = isUnknown ? 0.0 : (percentage / 100.0).clamp(0.0, 1.0);
    
    // Choose color based on battery level
    Color progressColor;
    if (isUnknown) {
      progressColor = AppColors.surfaceBorder;
    } else if (isCharging) {
      progressColor = AppColors.batteryCharging;
    } else {
      progressColor = AppColors.batteryColor(percentage);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: size / 2,
          lineWidth: size * 0.1,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 1200,
          curve: Curves.easeOutCubic,
          percent: displayPercent,
          center: isUnknown
              ? const Icon(Icons.question_mark, color: AppColors.textTertiary, size: 20)
              : isCharging
                  ? Icon(Icons.bolt, color: progressColor, size: size * 0.4)
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms, color: Colors.white)
                  : Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: AppColors.surfaceBorder,
          progressColor: progressColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isUnknown ? AppColors.textTertiary : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
