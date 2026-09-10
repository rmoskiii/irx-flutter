import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/score_feedback.dart';
import '../widgets/score_ring.dart';
import 'scenario_screen.dart';

/// Reveal order is narrative, not structural: consequence → each aftermath
/// slot in authored order → final message → reflection → ledger → totals.
/// The aftermath blocks land BEFORE any summary of the player, because they
/// should learn what happened to everyone else before being told what it
/// says about them.
///
/// Stages are integers rather than an enum because the number of aftermath
/// blocks is scenario-authored — The Secret sends two (jessica, alex), The
/// Prince sends three (money, data, everyone_else), and a future scenario
/// may send one or none. The stage indices below are computed from the map
/// the backend actually sent.
class OutcomeScreen extends StatefulWidget {
  final DistrictTheme district;
  final String scenarioId;

  /// Still accumulated, still flows to the home-screen stat pool via
  /// AppState. Only rendered here when the scenario grades on score tiers.
  final StatDelta totalScores;
  final String consequence;

  /// Tier explanation. Present only if the scenario authored `outcomeTiers`.
  /// No longer mutually exclusive with the reflection — a scenario may send
  /// both, in which case the reflection is the headline and this sits under
  /// it as a secondary line.
  final String outcomeExplanation;

  /// Pattern-matched prose. When present, the ring and numeric totals are
  /// suppressed: a scenario that reflects should not also be handing out a
  /// number as its verdict.
  final String? reflectionTitle;
  final String? reflectionText;

  /// Slot-keyed aftermath. Keys are authored by the scenario and rendered
  /// as labels, so they're written knowing they'll be shown. Insertion
  /// order from the JSON is preserved through jsonDecode and drives both
  /// display order and reveal order.
  final Map<String, String>? aftermath;

  final String? finalMessage;

  final List<TurnBreakdown> breakdown;

  /// Whether this scenario's score dimensions may be shown to the player.
  /// Declared by the scenario; defaults true so every scenario that predates
  /// the field renders exactly as before. When false the ledger is suppressed
  /// — the ring and totals are already suppressed independently by
  /// [isReflectionMode], which is a different and older condition.
  final bool playerVisible;

  const OutcomeScreen({
    super.key,
    required this.district,
    required this.scenarioId,
    required this.totalScores,
    required this.consequence,
    required this.outcomeExplanation,
    this.reflectionTitle,
    this.reflectionText,
    this.aftermath,
    this.finalMessage,
    required this.breakdown,
    this.playerVisible = true,
  });

  bool get isReflectionMode =>
      reflectionTitle != null && reflectionTitle!.isNotEmpty;

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> {
  static const _turnStagger = Duration(milliseconds: 300);
  static const _sectionFade = Duration(milliseconds: 620);
  static const _minHold = Duration(milliseconds: 1600);
  static const _maxHold = Duration(milliseconds: 6000);

  int _stage = 0;
  int _revealedTurns = 0;

  DistrictTheme get district => widget.district;
  StatDelta get totalScores => widget.totalScores;
  List<TurnBreakdown> get breakdown => widget.breakdown;
  bool get _reflectionMode => widget.isReflectionMode;
  bool get _playerVisible => widget.playerVisible;

  /// Empty-valued slots are dropped here rather than rendered as a bare
  /// header, so a scenario whose variants didn't all match doesn't leave a
  /// labelled gap on the screen.
  late final List<MapEntry<String, String>> _slots = (widget.aftermath ?? {})
      .entries
      .where((e) => e.value.trim().isNotEmpty)
      .toList(growable: false);

  bool get _hasTier => widget.outcomeExplanation.trim().isNotEmpty;
  bool get _hasFinal =>
      widget.finalMessage != null && widget.finalMessage!.trim().isNotEmpty;

  static const int _stConsequence = 1;
  int _stSlot(int i) => 2 + i;
  int get _stFinalMessage => 2 + _slots.length;
  int get _stReflection => _stFinalMessage + 1;
  int get _stBreakdown => _stReflection + 1;
  int get _stScore => _stBreakdown + 1;
  int get _stActions => _stScore + 1;

  bool _at(int stage) => _stage >= stage;

  /// Hold proportional to how much there is to read. Aftermath blocks run
  /// 60–90 words and are the payoff of the whole scenario — a flat 1.5s
  /// buries them.
  Duration _holdFor(String? text) {
    if (text == null || text.trim().isEmpty) return Duration.zero;
    final words = text.trim().split(RegExp(r'\s+')).length;
    final ms = words * 270;
    return Duration(
      milliseconds: ms.clamp(_minHold.inMilliseconds, _maxHold.inMilliseconds),
    );
  }

  @override
  void initState() {
    super.initState();
    _runReveal();
  }

  Future<bool> _advance(int to, {Duration? after}) async {
    if (after != null && after > Duration.zero) {
      await Future.delayed(after);
    }
    if (!mounted) return false;
    setState(() => _stage = to);
    return true;
  }

  Future<void> _runReveal() async {
    if (!await _advance(_stConsequence,
        after: const Duration(milliseconds: 180))) return;

    // Each slot holds for the length of whatever preceded it.
    var previous = widget.consequence;
    for (var i = 0; i < _slots.length; i++) {
      if (!await _advance(_stSlot(i), after: _holdFor(previous))) return;
      previous = _slots[i].value;
    }

    if (!await _advance(_stFinalMessage, after: _holdFor(previous))) return;
    if (!await _advance(_stReflection, after: _holdFor(widget.finalMessage))) {
      return;
    }

    if (!await _advance(_stBreakdown,
        after: _holdFor(widget.reflectionText ?? widget.outcomeExplanation))) {
      return;
    }

    for (var i = 0; i < breakdown.length; i++) {
      setState(() => _revealedTurns = i + 1);
      await Future.delayed(_turnStagger);
      if (!mounted) return;
    }

    if (!await _advance(_stScore, after: const Duration(milliseconds: 420))) {
      return;
    }

    await _advance(_stActions, after: const Duration(milliseconds: 650));
  }

  @override
  Widget build(BuildContext context) {
    final displayScore = (50 + totalScores.total).clamp(0, 100);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Text('OUTCOME', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 20),

                // The immediate consequence of the final choice.
                _RevealIn(
                  visible: _at(_stConsequence),
                  duration: _sectionFade,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.consequence,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),

                // Aftermath, one labelled block per slot. Reading them back
                // to back is what makes an asymmetric outcome legible as
                // asymmetric — two friendships in The Secret, three kinds of
                // damage in The Prince.
                for (var i = 0; i < _slots.length; i++)
                  _RevealIn(
                    visible: _at(_stSlot(i)),
                    duration: _sectionFade,
                    child: _AftermathBlock(
                      label: _slotLabel(_slots[i].key),
                      text: _slots[i].value,
                      district: district,
                    ),
                  ),

                // The pattern reveal. No header — it isn't about any one of
                // them, it's the thing sitting underneath all of it.
                if (_hasFinal)
                  _RevealIn(
                    visible: _at(_stFinalMessage),
                    duration: _sectionFade,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 1,
                            color: district.accent.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.finalMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Reflection, tier explanation, or both. When a scenario
                // sends both, the reflection is the headline and the tier
                // line sits beneath it, dimmed — it's a coarser statement
                // about the same run, not a competing one.
                _RevealIn(
                  visible: _at(_stReflection),
                  duration: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
                        if (_reflectionMode)
                          _ReflectionBlock(
                            title: widget.reflectionTitle!,
                            text: widget.reflectionText ?? '',
                            district: district,
                          ),
                        if (_reflectionMode && _hasTier)
                          const SizedBox(height: 18),
                        if (_hasTier)
                          Text(
                            widget.outcomeExplanation,
                            textAlign: TextAlign.center,
                            style: _reflectionMode
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.6,
                                    )
                                : Theme.of(context).textTheme.bodyLarge,
                          ),
                      ],
                    ),
                  ),
                ),

                // Ledger suppressed when the scenario declares its scores
                // are not player-facing. The stage still advances and holds so
                // the indices below it don't shift.
                if (_playerVisible && _at(_stBreakdown) && _revealedTurns > 0) ...[
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HOW WE GOT HERE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final turn in breakdown.take(_revealedTurns))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BreakdownTurn(turn: turn, district: district),
                    ),
                ],

                // Ring + totals suppressed entirely in reflection mode.
                if (!_reflectionMode)
                  _RevealIn(
                    visible: _at(_stScore),
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          ScoreRing(score: displayScore, color: district.accent),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'TOTALS',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatDeltaRow(
                              label: 'SAVVY', value: totalScores.savvy),
                          _StatDeltaRow(
                              label: 'INTEGRITY', value: totalScores.integrity),
                          _StatDeltaRow(
                              label: 'STREET SMARTS',
                              value: totalScores.streetSmarts),
                        ],
                      ),
                    ),
                  ),

                _RevealIn(
                  visible: _at(_stActions),
                  duration: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
                        // Applies regardless of grading mode (reflection or
                        // tier) — the premise that different choices
                        // produce a different outcome holds either way.
                        // Sits directly above Replay so the invitation is
                        // read immediately before the button that acts on
                        // it.
                        Text(
                          "Replay this scenario to see how the outcome "
                          "could've changed with different responses.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: district.accent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                            child: const Text('Continue'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color:
                                      district.accent.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ScenarioScreen(
                                  district: district,
                                  scenarioIdOverride: widget.scenarioId,
                                ),
                              ),
                            ),
                            child: const Text('Replay this scenario'),
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

/// Slot keys are authored to be displayed. Underscores become spaces so a
/// scenario can write `everyone_else` and get "EVERYONE ELSE" without the
/// client holding a per-scenario label table.
String _slotLabel(String key) =>
    key.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();

/// One aftermath slot, headed by its label.
class _AftermathBlock extends StatelessWidget {
  final String label;
  final String text;
  final DistrictTheme district;

  const _AftermathBlock({
    required this.label,
    required this.text,
    required this.district,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: district.labelFont().copyWith(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: district.accent,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: district.accent.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
        ],
      ),
    );
  }
}

/// Short title plus pattern-matched prose. Typographic, not iconographic:
/// no ring, no badge, no score-shaped container.
class _ReflectionBlock extends StatelessWidget {
  final String title;
  final String text;
  final DistrictTheme district;

  const _ReflectionBlock({
    required this.title,
    required this.text,
    required this.district,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: district.labelFont().copyWith(
                fontSize: 13,
                letterSpacing: 1.1,
                color: district.accent,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

class _RevealIn extends StatelessWidget {
  final bool visible;
  final Duration duration;
  final Widget child;

  const _RevealIn({
    required this.visible,
    required this.duration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: visible
          ? KeyedSubtree(key: const ValueKey('visible'), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

class _BreakdownTurn extends StatelessWidget {
  final TurnBreakdown turn;
  final DistrictTheme district;

  const _BreakdownTurn({required this.turn, required this.district});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201c${turn.choiceLabel}\u201d',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 6),
          ScoreFeedback(
            scores: turn.scores,
            reasons: turn.reasons,
            district: district,
          ),
        ],
      ),
    );
  }
}

class _StatDeltaRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatDeltaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            '${positive ? '+' : ''}$value',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
