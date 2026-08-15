import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import 'choice_tile.dart';

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
  bool _choicesVisible = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < widget.thread.length; i++) {
      await Future.delayed(widget.thread[i].isBubble ? _bubbleGap : _narrationGap);
      if (!mounted) return;
      setState(() => _revealed = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 320));
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
              MessagesCard(
                district: widget.district,
                contactName: character['name'] as String? ?? '',
                contactRole: character['role'] as String? ?? '',
                thread: widget.thread,
                revealedSegments: _revealed,
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
}