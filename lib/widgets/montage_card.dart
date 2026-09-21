import 'package:flutter/material.dart';
import '../models/scene_render.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import 'scene_view.dart';

/// Compressed time: three vignette panels composed server-side, then the prose.
///
/// A montage node has no speaker, so unlike [SceneCard] there is no character
/// header — the panels ARE the picture of time passing, and the message is the
/// narration of it. Before this card existed a `montage` node fell through to
/// a plain persona bubble and the composed panels were dropped on the floor:
/// The Streets has three of them (s1d2_run, s1d5_stall, s1d6_mum).
///
/// The frame is the same 16:9 canvas as every scene, so [SceneView] draws it
/// unchanged. With no artwork (a render failure the server logged) it degrades
/// to the prose alone, never to an empty frame.
class MontageCard extends StatelessWidget {
  static const revealDuration = Duration(milliseconds: 500);

  final DistrictTheme district;
  final String location;
  final String message;
  final SceneRender? render;

  const MontageCard({
    super.key,
    required this.district,
    required this.location,
    required this.message,
    this.render,
  });

  @override
  Widget build(BuildContext context) {
    final scene = render;
    final text = Theme.of(context).textTheme;

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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: district.accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (scene != null)
              SceneView(
                svg: scene.svg,
                cacheKey: scene.cacheKey,
                semanticLabel: location.isEmpty ? 'Time passing' : location,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (location.isNotEmpty) ...[
                    Text(
                      location.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: district.accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (message.trim().isNotEmpty)
                    Text(
                      message,
                      style: text.bodyLarge?.copyWith(height: 1.55),
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