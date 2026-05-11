import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/audio_device.dart';
import '../theme/app_theme.dart';

/// Overlay that appears when audio output is switched (similar to Windows volume flyout).
class AudioSwitchOverlay extends StatelessWidget {
  const AudioSwitchOverlay({
    super.key,
    required this.device,
    required this.onClose,
  });

  final AudioDevice device;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 60.0, left: 20.0),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: GlassDecoration.card(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Audio Output Switched',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          device.shortName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // A mock volume slider for visuals
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: device.volume,
                          backgroundColor: AppColors.surfaceBorder,
                          color: AppColors.primary,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate()
             .slideX(begin: -1.0, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
             .fadeIn(),
          ),
        ),
      ),
    );
  }
}
