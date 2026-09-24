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
    this.caption,
  });

  final String text;

  /// Resolved height in logical pixels, floor or expanded. The shell computes
  /// it; see CinematicShell.panelHeight.
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

  /// The scene's location line — "The kitchen", "Outside the shops, eight".
  final String? caption;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final label = caption?.trim() ?? '';

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
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(22, 2, 22, bottomInset + 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label.isNotEmpty) ...[
                          Text(
                            label.toUpperCase(),
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
                      ],
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