import 'package:flutter/material.dart';
import '../models/scene_render.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';
import 'scene_avatar.dart';
import 'scene_view.dart';
import 'scene_visuals.dart';

/// Renders a "scene" presentation inline in the transcript, for moments
/// that don't warrant a full cinematic interruption.
///
/// When the node carries composed artwork the card leads with it and drops
/// both the setting plate and the initial-letter avatar: those exist to stand
/// in for a room and a face that didn't exist yet, and repeating them beside a
/// drawing of the same room and the same face is noise. Without artwork the
/// card is exactly what it always was.
class SceneCard extends StatelessWidget {
  static const revealDuration = Duration(milliseconds: 500);

  final DistrictTheme district;
  final String characterName;
  final String characterRole;
  final String mood;
  final String location;
  final String message;
  final Map<String, dynamic> data;

  /// Composed scene for this node, or null. Null is normal.
  final SceneRender? render;

  const SceneCard({
    super.key,
    required this.district,
    required this.characterName,
    required this.characterRole,
    required this.mood,
    required this.location,
    required this.message,
    this.data = const {},
    this.render,
  });

  @override
  Widget build(BuildContext context) {
    final moodStyle = MoodPalette.of(mood);
    final visual = SceneVisualStyle.fromData(district, {
      ...data,
      if (location.isNotEmpty) 'location': location,
    });
    final scene = render;
    final hasArtwork = scene != null;

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
        // No padding around the artwork — it runs edge to edge inside the
        // card's rounded corners, so the frame reads as a window rather than
        // as a picture hung on a panel.
        padding: hasArtwork ? EdgeInsets.zero : const EdgeInsets.all(14),
        clipBehavior: hasArtwork ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.surfaceRaised, visual.colors.first, 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: moodStyle.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasArtwork)
              SceneView(
                svg: scene.svg,
                cacheKey: scene.cacheKey,
                headAnchors: const {},
                semanticLabel: location.isEmpty
                    ? characterName
                    : '$characterName, $location',
              )
            else ...[
              SceneSettingPlate(
                visual: visual,
                mood: moodStyle,
                district: district,
                compact: true,
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: hasArtwork
                  ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
                  : EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The artwork already shows who is speaking and where.
                  if (!hasArtwork) ...[
                    SceneAvatar(
                      initial:
                          characterName.isNotEmpty ? characterName[0] : '?',
                      mood: moodStyle,
                      accent: district.accent,
                      size: 46,
                    ),
                    const SizedBox(width: 14),
                  ],
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
            ),
          ],
        ),
      ),
    );
  }
}