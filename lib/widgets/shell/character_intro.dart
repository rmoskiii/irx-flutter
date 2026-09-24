import 'dart:ui';

import 'package:flutter/material.dart';

/// A character's first appearance, as a lower-third over the scene.
///
/// The film convention rather than the app one: it fades in, states who this
/// is, and leaves. Nothing to tap, nothing to dismiss, and the scenario does
/// not wait for it — the prose is readable underneath it the whole time.
///
/// It occupies the same band the choices use, which is why the shell holds the
/// choices and the speech bubble back until it has gone: the band carries one
/// thing at a time, and an introduction competing with a line of dialogue for
/// the same strip of screen would lose to it.
class CharacterIntro extends StatelessWidget {
  const CharacterIntro({
    super.key,
    required this.name,
    required this.line,
    required this.accent,
    required this.labelFont,
  });

  final String name;
  final String line;
  final Color accent;

  /// The district's own label face, so the introduction is in the same voice as
  /// the day chip rather than a second typographic system.
  final TextStyle Function() labelFont;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 16, 13),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: accent, width: 3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: labelFont().copyWith(
                        fontSize: 15,
                        letterSpacing: 2.2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      line,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}