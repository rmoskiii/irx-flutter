import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

class DistrictCard extends StatelessWidget {
  final DistrictTheme district;
  final double progress;
  final VoidCallback? onTap;

  const DistrictCard({
    super.key,
    required this.district,
    this.progress = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!district.available) {
      return _LockedCard(district: district);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: district.accent.withOpacity(0.35)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: district.backgroundGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: AmbientGlow(color: district.accent, size: 140),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district.name.toUpperCase(),
                  style: district.labelFont().copyWith(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: district.accent,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  district.tagline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: district.accent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(district.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(district.icon, size: 18, color: district.accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final DistrictTheme district;
  const _LockedCard({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Opacity(
        opacity: 0.55,
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(district.name, style: Theme.of(context).textTheme.bodyLarge),
                  Text(district.tagline, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
