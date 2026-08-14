import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';
import 'scene_avatar.dart';

/// The full cinematic treatment for a "scene" presentation flagged
/// `modal: true` - a soft-focus aurora backdrop tinted to the character's
/// mood, a large breathing portrait, and a glassmorphic dialogue panel
/// with the response choices inside it. Same "choices live in the modal"
/// contract as [CallModal] and [PaymentRequestModal].
class SceneModal extends StatefulWidget {
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
  State<SceneModal> createState() => _SceneModalState();
}

class _SceneModalState extends State<SceneModal> {
  static const _revealDuration = Duration(milliseconds: 380);
  static const _choiceStaggerDelay = Duration(milliseconds: 95);
  static const _choiceCommitDelay = Duration(milliseconds: 140);

  int _visibleChoiceCount = 0;
  String? _selectedChoiceId;

  bool get _choicesLocked => _selectedChoiceId != null;

  @override
  void initState() {
    super.initState();
    _revealChoices();
  }

  Future<void> _revealChoices() async {
    await Future.delayed(_revealDuration);
    for (var i = 0; i < widget.choices.length; i++) {
      await Future.delayed(_choiceStaggerDelay);
      if (!mounted || _selectedChoiceId != null) return;
      setState(() => _visibleChoiceCount = i + 1);
    }
  }

  Future<void> _selectChoice(ScenarioChoice choice) async {
    if (_choicesLocked) return;
    setState(() => _selectedChoiceId = choice.id);
    await Future.delayed(_choiceCommitDelay);
    if (!mounted) return;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.data['character'] as Map<String, dynamic>? ?? {};
    final name = character['name'] as String? ?? '';
    final role = character['role'] as String? ?? '';
    final mood = character['mood'] as String? ?? '';
    final location = widget.data['location'] as String? ?? '';
    final moodStyle = MoodPalette.of(mood);
    final district = widget.district;
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
              Container(
                  color: Color.fromRGBO(
                      8, 8, 10, 1.0 - moodStyle.atmosphereBrightness)),

              // Aurora backdrop - large soft-focus color blobs, blurred
              // into a wash. This is the "looks expensive" background
              // layer - a mesh-gradient effect built from plain shapes.
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                      sigmaX: moodStyle.atmosphereBlur,
                      sigmaY: moodStyle.atmosphereBlur),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60,
                        left: -40,
                        child: _AuroraBlob(
                            color: moodStyle.primary,
                            size: 260,
                            opacity: moodStyle.atmosphereOpacity),
                      ),
                      Positioned(
                        bottom: -80,
                        right: -60,
                        child: _AuroraBlob(
                            color: moodStyle.secondary,
                            size: 280,
                            opacity: moodStyle.atmosphereOpacity),
                      ),
                      Positioned(
                        top: 120,
                        right: -40,
                        child: _AuroraBlob(
                            color: district.accent,
                            size: 180,
                            opacity: moodStyle.atmosphereOpacity),
                      ),
                    ],
                  ),
                ),
              ),

              // Content.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: _revealDuration,
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.14)),
                            ),
                            child: Text(
                              widget.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.55,
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      if (_visibleChoiceCount > 0) ...[
                        const SizedBox(height: 24),
                        Text(
                          'HOW DO YOU RESPOND?',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                        ),
                        const SizedBox(height: 10),
                        for (final choice
                            in widget.choices.take(_visibleChoiceCount))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('scene-choice-${choice.id}'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 8),
                                  child: child,
                                ),
                              ),
                              child: _SceneChoiceButton(
                                label: choice.label,
                                accent: widget.district.accent,
                                disabled: _selectedChoiceId != null,
                                selected: _selectedChoiceId == choice.id,
                                onTap: () => _selectChoice(choice),
                              ),
                            ),
                          ),
                      ],
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
  final double opacity;

  const _AuroraBlob(
      {required this.color, required this.size, this.opacity = 0.55});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

class _SceneChoiceButton extends StatelessWidget {
  final String label;
  final Color accent;
  final bool disabled;
  final bool selected;
  final VoidCallback onTap;

  const _SceneChoiceButton({
    required this.label,
    required this.accent,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: selected
              ? accent.withOpacity(0.16)
              : Colors.white.withOpacity(0.05),
          child: InkWell(
            onTap: disabled ? null : onTap,
            splashColor: accent.withOpacity(0.2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? accent.withOpacity(0.65)
                      : Colors.white.withOpacity(0.14),
                ),
              ),
              child: Opacity(
                opacity: disabled && !selected ? 0.42 : 1,
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.3),
                ),
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
    builder: (_) => SceneModal(
        district: district, data: data, message: message, choices: choices),
  );
}
