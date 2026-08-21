import 'package:flutter/material.dart';
import '../models/scenario_intro.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// The framing card shown once, before the first node of a scenario.
///
/// District-themed like every other surface — accent, gradient-adjacent
/// dark panel, district label font on the eyebrow and title — so it reads
/// as the front door to that world rather than a generic system dialog.
///
/// Resolves when dismissed. Callers await it before populating the
/// transcript, so a modal-presentation root node can never stack on top
/// of this.
class ScenarioIntroModal extends StatelessWidget {
  final DistrictTheme district;
  final ScenarioIntro intro;

  /// True on a replay. Lets the player tap the barrier away instead of
  /// reading the same card a second time.
  final bool dismissible;

  const ScenarioIntroModal({
    super.key,
    required this.district,
    required this.intro,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 44),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430, maxHeight: 660),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: district.accent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: district.accent.withValues(alpha: 0.12),
                  blurRadius: 48,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 26, 26, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Eyebrow — district identity.
                        Row(
                          children: [
                            Icon(district.icon,
                                size: 14, color: district.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                intro.eyebrow,
                                style: district.labelFont().copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.4,
                                      color: district.accent,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          intro.title,
                          style: district.labelFont().copyWith(
                                fontSize: 28,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Container(height: 1, color: AppColors.border),
                        const SizedBox(height: 18),
                        Text(
                          intro.situation,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.65),
                        ),
                        if (intro.youAre.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _YouAre(district: district, text: intro.youAre),
                        ],
                        if (intro.rules.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Text(
                            'BEFORE YOU START',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 10),
                          for (final rule in intro.rules)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _RuleLine(
                                  district: district, text: rule),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Footer: duration + the only way forward.
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        intro.duration,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                      const Spacer(),
                      _BeginButton(
                        district: district,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YouAre extends StatelessWidget {
  final DistrictTheme district;
  final String text;

  const _YouAre({required this.district, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: district.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: district.accent.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final DistrictTheme district;
  final String text;

  const _RuleLine({required this.district, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: district.accent.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12.5, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _BeginButton extends StatelessWidget {
  final DistrictTheme district;
  final VoidCallback onTap;

  const _BeginButton({required this.district, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: district.accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: district.accent.withValues(alpha: 0.22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: district.accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Begin',
                style: district.labelFont().copyWith(
                      fontSize: 13,
                      letterSpacing: 0.6,
                      color: district.accent,
                    ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: district.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the intro and resolves once dismissed.
Future<void> showScenarioIntro(
  BuildContext context, {
  required DistrictTheme district,
  required ScenarioIntro intro,
  bool dismissible = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (_) => ScenarioIntroModal(
      district: district,
      intro: intro,
      dismissible: dismissible,
    ),
  );
}