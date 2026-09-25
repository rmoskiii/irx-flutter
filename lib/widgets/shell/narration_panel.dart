import 'dart:ui';

import 'package:flutter/material.dart';

/// The prose, on translucent glass at the bottom of the shell.
///
/// Always present, never a sheet that has to be summoned: the panel's floor is
/// the narration itself, sized so the whole of a short passage is readable
/// without touching anything. Dragging or tapping the grip raises it to read a
/// long one. The scene behind it does not move either way — [height] is decided
/// by the shell, which owns the geometry, so the panel has no opinion about how
/// much room it gets.
///
/// Its header carries who is in the room. That is the persistent half of the
/// character treatment: the lower-third introduces someone once, and from then
/// on their name and relationship are here for as long as the interaction
/// lasts. The location is still shown, demoted — the person is the information.
class NarrationPanel extends StatelessWidget {
  const NarrationPanel({
    super.key,
    required this.text,
    required this.height,
    required this.expanded,
    required this.onToggle,
    required this.onDrag,
    required this.accent,
    required this.bottomInset,
    required this.labelFont,
    this.characterName,
    this.relationship,
    this.location,
    this.beat,
    this.onBeatContinue,
    this.referenceName,
    this.referenceTag,
    this.footer,
  });

  final String text;

  /// Resolved height in logical pixels, floor or expanded. The shell computes
  /// it; see CinematicShell.panelFloor.
  final double height;

  final bool expanded;
  final VoidCallback onToggle;

  /// Vertical drag in logical pixels — negative is upward. The shell decides
  /// what a drag means, so a future third detent needs no change here.
  final ValueChanged<double> onDrag;

  final Color accent;

  /// The device's bottom safe inset, already included in [height]. Held
  /// separately so the text can clear the home indicator while the glass
  /// itself runs to the bottom of the screen.
  final double bottomInset;

  /// The district's label face, shared with the day chip and the lower-third.
  final TextStyle Function() labelFont;

  /// Who the beat belongs to, and what they are to the player. Both null on a
  /// node with no character — an empty room, a montage — and then the location
  /// leads instead.
  final String? characterName;
  final String? relationship;

  final String? location;

  /// The ripple of the choice just made, held for its reading time before the
  /// next node lands. Shown under the prose rather than replacing it: the scene
  /// has not changed yet, so neither should the passage describing it.
  final String? beat;

  /// Tapping anywhere on the panel while a beat is up. The beat holds until the
  /// player moves it on — a reader who has finished should not wait, and one
  /// who has not should not be overtaken.
  final VoidCallback? onBeatContinue;

  /// Someone named in this passage who is not in the room and has not been met
  /// yet — shown once, under the prose that named them, as a single line.
  final String? referenceName;
  final String? referenceTag;

  /// Choices hosted inside the panel instead of floating over the artwork. Used
  /// for the seven-choice finale, where the room is empty and the choosing IS
  /// the scene.
  final Widget? footer;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final name = characterName?.trim() ?? '';
    final rel = relationship?.trim() ?? '';
    final place = location?.trim() ?? '';
    final ripple = beat?.trim() ?? '';
    final refName = referenceName?.trim() ?? '';
    final refTag = referenceTag?.trim() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
                  child: SizedBox(
                    height: 26,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: expanded ? 54 : 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // A beat takes the whole panel rather than sitting under the
                  // passage it follows: the player has just chosen, and this is
                  // what their choice did. Crossfaded so the swap reads as the
                  // scene answering, not as a new screen.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: ripple.isNotEmpty
                        ? KeyedSubtree(
                            key: ValueKey<String>('beat:$ripple'),
                            child: _BeatView(
                              text: ripple,
                              accent: accent,
                              bottomInset: bottomInset,
                              onContinue: onBeatContinue,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey<String>('reading'),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(22, 2, 22, bottomInset + 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (name.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name.toUpperCase(),
                                            style: labelFont().copyWith(
                                              fontSize: 13,
                                              letterSpacing: 1.8,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                        if (place.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              place,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                letterSpacing: 0.4,
                                                color: Colors.white
                                                    .withValues(alpha: 0.42),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (rel.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          rel,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color:
                                                Colors.white.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                  ] else if (place.isNotEmpty) ...[
                                    Text(
                                      place.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 1.6,
                                        fontWeight: FontWeight.w600,
                                        color: accent.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      height: 1.58,
                                      color: Colors.white.withValues(alpha: 0.94),
                                    ),
                                  ),
                                  if (refName.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: refName.toUpperCase(),
                                            style: labelFont().copyWith(
                                              fontSize: 11.5,
                                              letterSpacing: 1.6,
                                              color: accent.withValues(alpha: 0.85),
                                            ),
                                          ),
                                          if (refTag.isNotEmpty)
                                            TextSpan(
                                              text: '  ·  $refTag',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.white.withValues(alpha: 0.55),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (footer != null) ...[
                                    const SizedBox(height: 18),
                                    footer!,
                                  ],
                                ],
                              ),
                            ),
                          ),
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

/// The consequence of a choice, given the panel to itself until the player
/// taps on. The hint arrives late and quiet so it does not compete with the
/// first read.
class _BeatView extends StatelessWidget {
  const _BeatView({
    required this.text,
    required this.accent,
    required this.bottomInset,
    this.onContinue,
  });

  final String text;
  final Color accent;
  final double bottomInset;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onContinue,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, bottomInset + 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: accent.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              curve: const Interval(0.55, 1, curve: Curves.easeOut),
              builder: (context, v, child) => Opacity(opacity: v, child: child),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Tap to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}