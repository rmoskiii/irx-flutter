import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/scenario.dart';

/// The choices, floating on glass in the band between the figure and the panel.
///
/// They arrive one at a time because the SCREEN adds them one at a time — the
/// reading hold before the first and the 95ms stagger between them both live in
/// ScenarioScreen, where the node's timing already lives. This widget animates
/// whatever it is handed, which is why it stays a StatelessWidget and why the
/// timing cannot drift from the rest of the turn.
///
/// Bottom-aligned inside the band rather than centred: it keeps the tiles clear
/// of faces when there are two of them, and keeps the tap targets in the same
/// place whether there are two or five.
class ChoiceLayer extends StatelessWidget {
  const ChoiceLayer({
    super.key,
    required this.choices,
    required this.nodeId,
    required this.onTap,
    required this.accent,
    this.selectedId,
    this.locked = false,
    this.maxWidth = 420,
  });

  final List<ScenarioChoice> choices;

  /// Only used to key the entry animation, so tiles animate in on a new node
  /// instead of being reused in place.
  final String nodeId;

  final ValueChanged<ScenarioChoice> onTap;
  final Color accent;
  final String? selectedId;
  final bool locked;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        // reverse keeps the stack pinned to the bottom of the band and lets a
        // long list (the seven-choice finale is the only one) scroll upward
        child: SingleChildScrollView(
          reverse: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ChoiceStack(
            choices: choices,
            nodeId: nodeId,
            onTap: onTap,
            accent: accent,
            selectedId: selectedId,
            locked: locked,
          ),
        ),
      ),
    );
  }
}

/// The tiles themselves, without a position or a scroll of their own.
///
/// Extracted so the seven-choice finale can host the same tiles INSIDE the
/// narration panel: that node has no figure, so a floating band would leave
/// them hanging in an empty room, and the choosing is the whole scene. Two
/// placements, one set of tiles — the alternative was a second choice widget
/// that would drift from this one.
class ChoiceStack extends StatelessWidget {
  const ChoiceStack({
    super.key,
    required this.choices,
    required this.nodeId,
    required this.onTap,
    required this.accent,
    this.selectedId,
    this.locked = false,
  });

  final List<ScenarioChoice> choices;
  final String nodeId;
  final ValueChanged<ScenarioChoice> onTap;
  final Color accent;
  final String? selectedId;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              key: ValueKey<String>('choice-$nodeId-${choice.id}'),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 10),
                  child: child,
                ),
              ),
              child: _GlassChoice(
                label: choice.label,
                accent: accent,
                selected: selectedId == choice.id,
                disabled: locked,
                onTap: () => onTap(choice),
              ),
            ),
          ),
      ],
    );
  }
}

/// A choice tile that sits ON the artwork rather than under it: more
/// transparent than the narration panel, because the room behind it is worth
/// seeing and these are the lightest thing on the screen.
class _GlassChoice extends StatefulWidget {
  const _GlassChoice({
    required this.label,
    required this.accent,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_GlassChoice> createState() => _GlassChoiceState();
}

class _GlassChoiceState extends State<_GlassChoice> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fill = selected
        ? widget.accent.withValues(alpha: 0.26)
        : Colors.white.withValues(alpha: _pressed ? 0.16 : 0.09);
    final border = selected
        ? widget.accent.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel:
          widget.disabled ? null : () => setState(() => _pressed = false),
      onTapUp: widget.disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: selected ? 1.4 : 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Colors.white
                    .withValues(alpha: widget.disabled ? 0.55 : 0.96),
              ),
            ),
          ),
        ),
      ),
    );
  }
}