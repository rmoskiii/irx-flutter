import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/score_feedback.dart';
import '../widgets/score_ring.dart';
import 'scenario_screen.dart';

/// Reveal stages, in narrative order. The aftermath blocks land BEFORE the
/// reflection and the ledger: the player should learn what happened to
/// Jessica and Alex, and whose side each of them thinks they were on,
/// before being handed any summary of themselves.
enum _Stage {
  none,
  consequence,
  jessicaAftermath,
  alexAftermath,
  finalMessage,
  reflection,
  breakdown,
  score,
  actions,
}

class OutcomeScreen extends StatefulWidget {
  final DistrictTheme district;
  final String scenarioId;

  /// Still accumulated, still flows to the home-screen stat pool via
  /// AppState. Only rendered here in legacy (score-tier) mode.
  final StatDelta totalScores;
  final String consequence;
  final String outcomeExplanation;

  /// Reflection mode (The Secret). When [reflectionTitle] is non-null, no
  /// ring and no numeric headline are rendered.
  final String? reflectionTitle;
  final String? reflectionText;

  /// Aftermath prose. Rendered as two separately-labelled blocks so the
  /// asymmetry between the two friendships is impossible to miss.
  final String? jessicaAftermath;
  final String? alexAftermath;
  final String? finalMessage;

  final List<TurnBreakdown> breakdown;

  const OutcomeScreen({
    super.key,
    required this.district,
    required this.scenarioId,
    required this.totalScores,
    required this.consequence,
    required this.outcomeExplanation,
    this.reflectionTitle,
    this.reflectionText,
    this.jessicaAftermath,
    this.alexAftermath,
    this.finalMessage,
    required this.breakdown,
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

  _Stage _stage = _Stage.none;
  int _revealedTurns = 0;

  DistrictTheme get district => widget.district;
  StatDelta get totalScores => widget.totalScores;
  List<TurnBreakdown> get breakdown => widget.breakdown;
  bool get _reflectionMode => widget.isReflectionMode;

  bool _at(_Stage s) => _stage.index >= s.index;

  /// Hold proportional to how much there is to read. The aftermath blocks
  /// are 60-90 words each and are the emotional payoff of the whole
  /// scenario — a flat 1.5s buries them the way the old beat timing did.
  Duration _holdFor(String? text) {
    if (text == null || text.trim().isEmpty) return Duration.zero;
    final words = text.trim().split(RegExp(r'\s+')).length;
    final ms = words * 270;
    return Duration(
      milliseconds: ms.clamp(_minHold.inMilliseconds, _maxHold.inMilliseconds),
    );
  }

  String get _headline {
    final total = totalScores.total;
    if (total >= 60) return 'Excellent judgment.';
    if (total >= 25) return 'Good call.';
    if (total >= 0) return 'You got through it.';
    return 'That one stung.';
  }

  @override
  void initState() {
    super.initState();
    _runReveal();
  }

  Future<bool> _advance(_Stage to, {Duration? after}) async {
    if (after != null && after > Duration.zero) {
      await Future.delayed(after);
    }
    if (!mounted) return false;
    setState(() => _stage = to);
    return true;
  }

  Future<void> _runReveal() async {
    if (!await _advance(_Stage.consequence,
        after: const Duration(milliseconds: 180))) return;

    if (!await _advance(_Stage.jessicaAftermath,
        after: _holdFor(widget.consequence))) return;

    if (!await _advance(_Stage.alexAftermath,
        after: _holdFor(widget.jessicaAftermath))) return;

    if (!await _advance(_Stage.finalMessage,
        after: _holdFor(widget.alexAftermath))) return;

    if (!await _advance(_Stage.reflection,
        after: _holdFor(widget.finalMessage))) return;

    if (!await _advance(_Stage.breakdown,
        after: _holdFor(widget.reflectionText ?? widget.outcomeExplanation))) {
      return;
    }

    for (var i = 0; i < breakdown.length; i++) {
      setState(() => _revealedTurns = i + 1);
      await Future.delayed(_turnStagger);
      if (!mounted) return;
    }

    if (!await _advance(_Stage.score,
        after: const Duration(milliseconds: 420))) return;

    await _advance(_Stage.actions, after: const Duration(milliseconds: 650));
  }

  @override
  Widget build(BuildContext context) {
    final displayScore = (50 + totalScores.total).clamp(0, 100);
    final hasJessica =
        widget.jessicaAftermath != null && widget.jessicaAftermath!.isNotEmpty;
    final hasAlex =
        widget.alexAftermath != null && widget.alexAftermath!.isNotEmpty;
    final hasFinal =
        widget.finalMessage != null && widget.finalMessage!.isNotEmpty;

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
                  visible: _at(_Stage.consequence),
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

                // Two friendships, resolved separately and labelled by name.
                if (hasJessica)
                  _RevealIn(
                    visible: _at(_Stage.jessicaAftermath),
                    duration: _sectionFade,
                    child: _AftermathBlock(
                      name: 'JESSICA',
                      text: widget.jessicaAftermath!,
                      district: district,
                    ),
                  ),
                if (hasAlex)
                  _RevealIn(
                    visible: _at(_Stage.alexAftermath),
                    duration: _sectionFade,
                    child: _AftermathBlock(
                      name: 'ALEX',
                      text: widget.alexAftermath!,
                      district: district,
                    ),
                  ),

                // The loyalty reveal. No header — it isn't about either of
                // them individually, it's the thing sitting underneath both.
                if (hasFinal)
                  _RevealIn(
                    visible: _at(_Stage.finalMessage),
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

                // Reflection title + prose (or the legacy tier explanation).
                _RevealIn(
                  visible: _at(_Stage.reflection),
                  duration: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: _reflectionMode
                        ? _ReflectionBlock(
                            title: widget.reflectionTitle!,
                            text: widget.reflectionText ?? '',
                            district: district,
                          )
                        : Text(
                            widget.outcomeExplanation,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                  ),
                ),

                if (_at(_Stage.breakdown) && _revealedTurns > 0) ...[
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
                    visible: _at(_Stage.score),
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          ScoreRing(score: displayScore, color: district.accent),
                          const SizedBox(height: 16),
                          Text(_headline,
                              style: Theme.of(context).textTheme.titleLarge),
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
                  visible: _at(_Stage.actions),
                  duration: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
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

/// One character's aftermath, headed by their name. The name header is the
/// whole point — reading "JESSICA ... ALEX ..." back to back is what makes
/// an asymmetric outcome legible as asymmetric.
class _AftermathBlock extends StatelessWidget {
  final String name;
  final String text;
  final DistrictTheme district;

  const _AftermathBlock({
    required this.name,
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
                name,
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

/// Reflection-mode replacement for the numeric explanation — short title
/// plus pattern-matched prose. Typographic, not iconographic: no ring, no
/// badge, no score-shaped container.
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