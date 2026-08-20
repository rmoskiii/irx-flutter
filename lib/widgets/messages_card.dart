import 'dart:math';

import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';
import '../utils/reading_time.dart';
import 'choice_tile.dart';
import 'scene_visuals.dart';

/// Renders a "messages" node as a phone thread — bubbles for dialogue,
/// narration between them for prose. Thread structure comes straight
/// from the scenario JSON as a segment array, not parsed from a wall of
/// text, so a new character or an unusual name can never trip a regex.
///
/// [revealedSegments] caps how many are visible; the modal uses this to
/// land bubbles one at a time. Null = show them all (inline transcript).
class MessagesCard extends StatelessWidget {
  final DistrictTheme district;
  final String contactName;
  final String contactRole;
  final List<ThreadSegment> thread;
  final int? revealedSegments;

  const MessagesCard({
    super.key,
    required this.district,
    required this.contactName,
    required this.contactRole,
    required this.thread,
    this.revealedSegments,
  });

  @override
  Widget build(BuildContext context) {
    final visible = revealedSegments == null
        ? thread
        : thread.take(revealedSegments!.clamp(0, thread.length)).toList();

    // Track last sender so consecutive bubbles from the same person
    // don't repeat the label — reads like a real thread that way.
    String? lastSender;
    final rendered = <Widget>[];
    for (final segment in visible) {
      if (segment.isBubble) {
        final showSender = segment.from != lastSender;
        lastSender = segment.from;
        rendered.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ReceivedBubble(
            district: district,
            sender: showSender ? segment.from : null,
            text: segment.text ?? '',
          ),
        ));
      } else {
        lastSender = null;
        rendered.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ThreadNarration(text: segment.narration ?? ''),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThreadHeader(district: district, name: contactName, role: contactRole),
        const SizedBox(height: 14),
        ...rendered,
      ],
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  final DistrictTheme district;
  final String name;
  final String role;

  const _ThreadHeader({
    required this.district,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final accent = district.accent;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.14),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceivedBubble extends StatelessWidget {
  final DistrictTheme district;
  final String? sender;
  final String text;

  const _ReceivedBubble({
    required this.district,
    required this.sender,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  sender!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: district.accent.withValues(alpha: 0.55),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadNarration extends StatelessWidget {
  final String text;
  const _ThreadNarration({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.65,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Modal version — the thread lands one segment at a time, then the
/// choices arrive. Same signature/return contract as showSceneModal.
Future<ScenarioChoice?> showMessagesModal(
  BuildContext context, {
  required DistrictTheme district,
  required Map<String, dynamic> data,
  required List<ThreadSegment> thread,
  required List<ScenarioChoice> choices,
}) {
  return showDialog<ScenarioChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (_) => _MessagesModal(
      district: district,
      data: data,
      thread: thread,
      choices: choices,
    ),
  );
}

class _MessagesModal extends StatefulWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;
  final List<ThreadSegment> thread;
  final List<ScenarioChoice> choices;

  const _MessagesModal({
    required this.district,
    required this.data,
    required this.thread,
    required this.choices,
  });

  @override
  State<_MessagesModal> createState() => _MessagesModalState();
}

class _MessagesModalState extends State<_MessagesModal> {
  static const _bubbleGap = Duration(milliseconds: 620);
  static const _narrationGap = Duration(milliseconds: 420);

  int _revealed = 0;
  int? _typingIndex;
  bool _choicesVisible = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < widget.thread.length; i++) {
      final segment = widget.thread[i];
      if (segment.isBubble) {
        setState(() => _typingIndex = i);
      }
      await Future.delayed(segment.isBubble ? _bubbleGap : _narrationGap);
      if (!mounted) return;
      setState(() {
        _revealed = i + 1;
        _typingIndex = null;
      });
      final segmentText = segment.isBubble ? segment.text : segment.narration;
      await Future.delayed(readingHoldForText(
        segmentText ?? '',
        minMs: segment.isBubble ? 650 : 900,
        maxMs: segment.isBubble ? 2600 : 3200,
        msPerWord: 90,
      ));
      if (!mounted) return;
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _choicesVisible = true);
  }

  Future<void> _select(ScenarioChoice choice) async {
    if (_selectedId != null) return;
    setState(() => _selectedId = choice.id);
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.data['character'] as Map<String, dynamic>? ?? {};
    final location = widget.data['location'] as String? ?? '';
    final mood = character['mood'] as String? ?? '';
    final moodStyle = MoodPalette.of(mood);
    final visual = SceneVisualStyle.fromData(widget.district, widget.data);
    final typingSegment =
        _typingIndex == null ? null : widget.thread[_typingIndex!];
    final typingSender =
        typingSegment == null ? null : _senderForTypingBubble(_typingIndex!);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                    location.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: widget.district.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              SceneSettingPlate(
                visual: visual,
                mood: moodStyle,
                district: widget.district,
                compact: true,
              ),
              const SizedBox(height: 14),
              MessagesCard(
                district: widget.district,
                contactName: character['name'] as String? ?? '',
                contactRole: character['role'] as String? ?? '',
                thread: widget.thread,
                revealedSegments: _revealed,
              ),
              if (typingSegment != null && typingSegment.isBubble)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: _ThreadTypingBubble(
                    district: widget.district,
                    sender: typingSender,
                  ),
                ),
              if (_choicesVisible) ...[
                const SizedBox(height: 18),
                Text(
                  'HOW DO YOU RESPOND?',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                for (final choice in widget.choices)
                  ChoiceTile(
                    label: choice.label,
                    district: widget.district,
                    disabled: _selectedId != null,
                    selected: _selectedId == choice.id,
                    onTap: () => _select(choice),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _senderForTypingBubble(int index) {
    final sender = widget.thread[index].from;
    if (sender == null) return null;
    if (index == 0) return sender;
    final previous = widget.thread[index - 1];
    if (previous.isBubble && previous.from == sender) return null;
    return sender;
  }
}

class _ThreadTypingBubble extends StatefulWidget {
  final DistrictTheme district;
  final String? sender;

  const _ThreadTypingBubble({required this.district, required this.sender});

  @override
  State<_ThreadTypingBubble> createState() => _ThreadTypingBubbleState();
}

class _ThreadTypingBubbleState extends State<_ThreadTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  widget.sender!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: widget.district.accent.withValues(alpha: 0.45),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _ThreadTypingDot(
                    controller: _controller,
                    phase: i * 0.18,
                    color: widget.district.accent,
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

class _ThreadTypingDot extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final Color color;

  const _ThreadTypingDot({
    required this.controller,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + phase) % 1.0;
        final lift = -sin(t * pi) * 3;
        final opacity = (0.28 + sin(t * pi) * 0.5).clamp(0.25, 0.78);
        return Transform.translate(
          offset: Offset(0, lift),
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
