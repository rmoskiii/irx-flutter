import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// The illustrated district card on the home hub. When [DistrictTheme.
/// imagePath] is set, that image is the backdrop. Otherwise falls back to
/// a procedural "glow + silhouette" backdrop built from the district's
/// own accent and icon - no art asset required, but still reads as a
/// considered illustration rather than a flat color card.
class DistrictCard extends StatelessWidget {
  final DistrictTheme district;

  /// A short honest status line - e.g. "2 scenarios live" - shown in the
  /// district's accent color at the bottom of the card. Deliberately not
  /// a fabricated "Level N": there's no real progression system yet, so
  /// this shows what's actually true instead.
  final String statusLabel;
  final VoidCallback? onTap;

  const DistrictCard({
    super.key,
    required this.district,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!district.available) {
      return _LockedCard(district: district);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 152),
          decoration: BoxDecoration(
            border: Border.all(color: district.accent.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              // Backdrop layer - real image if we have one, otherwise
              // the procedural glow-and-silhouette treatment.
              Positioned.fill(
                child: district.imagePath != null
                    ? Image.asset(district.imagePath!, fit: BoxFit.cover)
                    : _ProceduralBackdrop(district: district),
              ),

              // Left-to-right scrim so text stays legible over the art
              // regardless of what's underneath it.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.background.withOpacity(0.94),
                        AppColors.background.withOpacity(0.55),
                        AppColors.background.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Foreground content.
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 210),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            district.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 19,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            district.tagline,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: district.labelFont().copyWith(
                            fontSize: 13,
                            color: district.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Chevron button - bottom right, overlapping the art.
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The no-art-asset-needed backdrop: a blurred glow tinted to the
/// district's accent, plus the district's own icon rendered large and
/// soft as a silhouette, bleeding off the right edge of the card. Reuses
/// the same "blur + tint + oversized motif" language as the scene
/// modals, so a card without commissioned art still reads as considered
/// rather than placeholder.
class _ProceduralBackdrop extends StatelessWidget {
  final DistrictTheme district;

  const _ProceduralBackdrop({required this.district});

  @override
  Widget build(BuildContext context) {
    final secondaryTint = district.backgroundGradient.length > 1
        ? district.backgroundGradient[1]
        : district.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: district.backgroundGradient,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft blurred color wash, positioned toward the right where
          // the "illustration" reads.
          Positioned(
            right: -30,
            top: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: district.accent.withOpacity(0.5),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryTint.withOpacity(0.6),
                ),
              ),
            ),
          ),

          // The oversized icon silhouette - the card's "motif," bleeding
          // off the edge like a piece of art rather than sitting neatly
          // inside the card.
          Positioned(
            right: -18,
            bottom: -22,
            child: Icon(
              district.icon,
              size: 150,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              district.icon,
              size: 142,
              color: district.accent.withOpacity(0.28),
            ),
          ),
        ],
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