import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';
import 'scene_avatar.dart';

/// The full cinematic treatment for a "scene" presentation flagged
/// `modal: true` - a soft-focus aurora backdrop tinted to the character's
/// mood, a large breathing portrait, and a glassmorphic dialogue panel
/// with the response choices inside it. Same "choices live in the modal"
/// contract as [CallModal] and [PaymentRequestModal].
class SceneModal extends StatelessWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;
  final String message;
  final List<ScenarioChoice> choices;

  const SceneModal({
    super.key,
    required this.district,
    required this.data,
    required this.message,
    required this.choices,
  });

  @override
  Widget build(BuildContext context) {
    final character = data['character'] as Map<String, dynamic>? ?? {};
    final name = character['name'] as String? ?? '';
    final role = character['role'] as String? ?? '';
    final mood = character['mood'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final moodStyle = MoodPalette.of(mood);
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Base - near-black so the aurora reads as light against
              // dark, not washed out.
              Container(color: const Color(0xFF08080A)),

              // Aurora backdrop - large soft-focus color blobs, blurred
              // into a wash. This is the "looks expensive" background
              // layer - a mesh-gradient effect built from plain shapes.
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60,
                        left: -40,
                        child: _AuroraBlob(color: moodStyle.primary, size: 260),
                      ),
                      Positioned(
                        bottom: -80,
                        right: -60,
                        child: _AuroraBlob(color: moodStyle.secondary, size: 280),
                      ),
                      Positioned(
                        top: 120,
                        right: -40,
                        child: _AuroraBlob(color: district.accent, size: 180),
                      ),
                    ],
                  ),
                ),
              ),

              // Content.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (location.isNotEmpty)
                        Center(
                          child: Text(
                            location.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: district.labelFont().copyWith(
                                  fontSize: 11,
                                  letterSpacing: 1.4,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Center(
                        child: SceneAvatar(
                          initial: name.isNotEmpty ? name[0] : '?',
                          mood: moodStyle,
                          accent: district.accent,
                          size: 108,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Glassmorphic dialogue panel.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.14)),
                            ),
                            child: Text(
                              message,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.55,
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'HOW DO YOU RESPOND?',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 10),
                      for (final choice in choices)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _SceneChoiceButton(
                            label: choice.label,
                            accent: district.accent,
                            onTap: () => Navigator.of(context).pop(choice),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _AuroraBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
      ),
    );
  }
}

class _SceneChoiceButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _SceneChoiceButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withOpacity(0.05),
          child: InkWell(
            onTap: onTap,
            splashColor: accent.withOpacity(0.2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the scene as a barrier-dismissible-false modal. Resolves with the
/// [ScenarioChoice] the player tapped - same contract as [showCallModal]
/// and [showPaymentRequestModal].
Future<ScenarioChoice?> showSceneModal(
  BuildContext context, {
  required DistrictTheme district,
  required Map<String, dynamic> data,
  required String message,
  required List<ScenarioChoice> choices,
}) {
  return showDialog<ScenarioChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (_) => SceneModal(district: district, data: data, message: message, choices: choices),
  );
}