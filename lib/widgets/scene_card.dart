import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';
import 'scene_avatar.dart';
import 'scene_visuals.dart';

/// Renders a "scene" presentation inline in the transcript, for moments
/// that don't warrant a full cinematic interruption. Same avatar
/// component as [SceneModal], just smaller and paired with a compact
/// speech bubble rather than a full-screen backdrop.
class SceneCard extends StatelessWidget {
  static const revealDuration = Duration(milliseconds: 500);

  final DistrictTheme district;
  final String characterName;
  final String characterRole;
  final String mood;
  final String location;
  final String message;
  final Map<String, dynamic> data;

  const SceneCard({
    super.key,
    required this.district,
    required this.characterName,
    required this.characterRole,
    required this.mood,
    required this.location,
    required this.message,
    this.data = const {},
  });

  @override
  Widget build(BuildContext context) {
    final moodStyle = MoodPalette.of(mood);
    final visual = SceneVisualStyle.fromData(district, {
      ...data,
      if (location.isNotEmpty) 'location': location,
    });

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: revealDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.surfaceRaised, visual.colors.first, 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: moodStyle.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SceneSettingPlate(
              visual: visual,
              mood: moodStyle,
              district: district,
              compact: true,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAvatar(
                  initial: characterName.isNotEmpty ? characterName[0] : '?',
                  mood: moodStyle,
                  accent: district.accent,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(characterName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '$characterRole · $location',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      ScenePressureLine(
                        visual: visual,
                        accent: moodStyle.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
