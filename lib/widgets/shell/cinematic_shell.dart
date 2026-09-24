import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/scenario.dart';
import '../../models/scene_render.dart';
import '../../theme/district_theme.dart';
import '../../utils/reading_time.dart';
import 'choice_layer.dart';
import 'narration_panel.dart';
import 'scene_stage.dart';
import 'speech_bubble.dart';

/// The full-screen presentation: scene, panel, choices.
///
/// It owns the GEOMETRY and nothing else. The turn — fetching, resuming, day
/// boundaries, interstitials, scoring, the outcome — stays in ScenarioScreen,
/// which hands this widget the current node and takes a choice back. That split
/// is what lets Streets run the shell while the other two districts keep the
/// transcript, with one state machine underneath both.
///
/// Three rules decide the layout:
///   1. The scene never moves. It is anchored to the top at a fixed camera and
///      is not re-laid-out by anything the panel or the choices do.
///   2. The panel's floor is the narration. It is raised to meet the bottom of
///      the artwork so there is never a strip of background between them.
///   3. The choices live in what is left, clear of the panel, and step out of
///      the way when the panel is expanded for reading.
class CinematicShell extends StatefulWidget {
  const CinematicShell({
    super.key,
    required this.district,
    required this.node,
    required this.choices,
    required this.onChoice,
    required this.onExit,
    this.selectedChoiceId,
    this.locked = false,
    this.busy = false,
  });

  final DistrictTheme district;

  /// The node on screen. Null only in the moment before the first one lands.
  final ScenarioNode? node;

  final List<ScenarioChoice> choices;
  final ValueChanged<ScenarioChoice> onChoice;
  final VoidCallback onExit;
  final String? selectedChoiceId;

  /// Input is closed — a choice is committing, or the turn is in flight.
  final bool locked;

  /// Waiting on the server, with nothing to choose yet.
  final bool busy;

  /// The panel at rest: tall enough for the narration, and at least tall enough
  /// to meet the bottom of the artwork with 24 to spare so the two never part.
  static double panelFloor(double height, double bottomInset, double artHeight) {
    return math.max(
      height * 0.34 + bottomInset,
      height - artHeight + 24,
    );
  }

  /// The panel raised to read a long passage. Never shorter than the floor.
  static double panelExpanded(double height, double bottomInset, double floor) {
    return math.max(floor, height * 0.62 + bottomInset);
  }

  @override
  State<CinematicShell> createState() => _CinematicShellState();
}

class _CinematicShellState extends State<CinematicShell> {
  bool _expanded = false;

  /// Which spoken line is on screen. Only one node in The Streets says two
  /// things, and two balloons at one mouth is a comic strip, not a beat — so
  /// the second replaces the first once the first has had its reading time.
  int _lineIndex = 0;
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _startDialogue();
  }

  @override
  void didUpdateWidget(covariant CinematicShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node?.nodeId != widget.node?.nodeId) {
      // a new node starts at the floor: the panel's height is a property of the
      // passage being read, not a setting the player carries between beats
      if (_expanded) setState(() => _expanded = false);
      _startDialogue();
    }
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    super.dispose();
  }

  List<SceneDialogue> get _lines => widget.node?.render?.dialogue ?? const [];

  void _startDialogue() {
    _lineTimer?.cancel();
    _lineIndex = 0;
    _queueNextLine();
  }

  void _queueNextLine() {
    final lines = _lines;
    if (_lineIndex >= lines.length - 1) return;
    _lineTimer = Timer(readingHoldForText(lines[_lineIndex].text), () {
      if (!mounted) return;
      setState(() => _lineIndex++);
      _queueNextLine();
    });
  }

  /// The line on screen, positioned at its speaker's mouth. Null when the node
  /// says nothing, when the speaker isn't in this frame, or when the frame
  /// reports no anchor for them — all ordinary states, and all of them mean the
  /// same thing here: draw no bubble.
  Widget? _bubble(Size size, EdgeInsets padding, double floor) {
    final lines = _lines;
    if (lines.isEmpty) return null;
    final line = lines[math.min(_lineIndex, lines.length - 1)];
    final anchor = widget.node?.render?.anchorFor(line.speaker);
    if (anchor == null) return null;

    return SpeechBubble(
      key: ValueKey<String>('${widget.node?.nodeId}-$_lineIndex'),
      text: line.text,
      mouth: ShellCamera.project(Offset(anchor.x, anchor.y), size.width),
      viewportWidth: size.width,
      // below the chrome row, not merely below the status bar: a bubble that
      // clears the notch but lands on the back button is still in the way
      topLimit: padding.top + 44,
      bottomLimit: size.height - floor - 8,
    );
  }

  void _onDrag(double dy) {
    if (dy < -6 && !_expanded) setState(() => _expanded = true);
    if (dy > 6 && _expanded) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.district;
    final media = MediaQuery.of(context);
    final size = media.size;
    final node = widget.node;

    final artHeight = ShellCamera.artHeight(size.width);
    final floor =
        CinematicShell.panelFloor(size.height, media.padding.bottom, artHeight);
    final panelHeight = _expanded
        ? CinematicShell.panelExpanded(size.height, media.padding.bottom, floor)
        : floor;

    final message = node?.message ?? '';
    final caption = node?.presentation?.data['location'] as String?;
    final bubble = _bubble(size, media.padding, floor);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: district.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          // 1. the scene, top-anchored and fixed
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SceneStage(
              svg: node?.render?.svg,
              cacheKey: node?.render?.cacheKey,
              background: district.backgroundGradient.last,
              semanticLabel: caption,
            ),
          ),

          // 2. the line being spoken, at the mouth. Before the choices in the
          //    stack so a tile is never blocked by a balloon.
          if (bubble != null) bubble,

          // 3. the choices, in the band between the figure and the panel.
          //    Measured against the FLOOR, not the current height, so they
          //    never jump when the panel moves — they fade instead.
          Positioned(
            top: media.padding.top + 44,
            left: 0,
            right: 0,
            bottom: floor + 12,
            child: IgnorePointer(
              ignoring: _expanded,
              child: AnimatedOpacity(
                opacity: _expanded ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: widget.busy && widget.choices.isEmpty
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: district.accent,
                            ),
                          ),
                        ),
                      )
                    : ChoiceLayer(
                        choices: widget.choices,
                        nodeId: node?.nodeId ?? '',
                        onTap: widget.onChoice,
                        accent: district.accent,
                        selectedId: widget.selectedChoiceId,
                        locked: widget.locked,
                      ),
              ),
            ),
          ),

          // 4. the panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NarrationPanel(
              text: message,
              height: panelHeight,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
              onDrag: _onDrag,
              accent: district.accent,
              bottomInset: media.padding.bottom,
              caption: caption,
            ),
          ),

          // 5. chrome, over everything: the only way out, and where you are
          Positioned(
            top: media.padding.top + 4,
            left: 4,
            right: 12,
            child: Row(
              children: [
                _ShellChip(
                  onTap: widget.onExit,
                  child: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.white),
                ),
                const Spacer(),
                if (node?.day != null)
                  _ShellChip(
                    child: Text(
                      'DAY ${node!.day}',
                      style: district.labelFont().copyWith(
                            fontSize: 11,
                            letterSpacing: 1.4,
                            color: district.accent,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A legibility backing for chrome that sits on artwork. Without it the back
/// arrow disappears into a light wall and reappears against a dark one.
class _ShellChip extends StatelessWidget {
  const _ShellChip({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
    if (onTap == null) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: chip,
    );
  }
}