import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/score_feedback.dart';
import '../widgets/score_ring.dart';
import 'scenario_screen.dart';

class OutcomeScreen extends StatefulWidget {
  final DistrictTheme district;

  /// Needed so "Replay" can relaunch the exact same scenario rather than
  /// falling back to whatever the backend's default happens to be.
  final String scenarioId;

  /// Sum of every turn's score delta across the whole playthrough, not
  /// just the final choice - so a 3-turn conversation shows credit (or
  /// blame) for the whole path, not only the last step.
  final StatDelta totalScores;
  final String consequence;
  final String outcomeExplanation;

  /// Every turn played, in order - the "how we got here" ledger. This is
  /// what makes the final totals feel earned rather than asserted. For
  /// districts that hide scores during play (Neighbourhood), this is
  /// also the FIRST time the player sees any of these numbers at all.
  final List<TurnBreakdown> breakdown;

  const OutcomeScreen({
    super.key,
    required this.district,
    required this.scenarioId,
    required this.totalScores,
    required this.consequence,
    required this.outcomeExplanation,
    required this.breakdown,
  });

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> {
  static const _proseHold = Duration(milliseconds: 1500);
  static const _turnStagger = Duration(milliseconds: 300);
  static const _sectionFade = Duration(milliseconds: 520);

  bool _showConsequence = false;
  bool _showExplanation = false;
  int _revealedTurns = 0;
  bool _showScore = false;
  bool _showActions = false;

  DistrictTheme get district => widget.district;
  StatDelta get totalScores => widget.totalScores;
  List<TurnBreakdown> get breakdown => widget.breakdown;

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

  Future<void> _runReveal() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showConsequence = true);

    await Future.delayed(_proseHold);
    if (!mounted) return;
    setState(() => _showExplanation = true);

    await Future.delayed(_proseHold);
    if (!mounted) return;
    for (var i = 0; i < breakdown.length; i++) {
      setState(() => _revealedTurns = i + 1);
      await Future.delayed(_turnStagger);
      if (!mounted) return;
    }

    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showScore = true);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _showActions = true);
  }

  @override
  Widget build(BuildContext context) {
    // A rough 0-100 read on the whole playthrough, purely for the ring
    // display - the real signal is the breakdown below it.
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
                _RevealIn(
                  visible: _showConsequence,
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
                _RevealIn(
                  visible: _showExplanation,
                  duration: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      widget.outcomeExplanation,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                if (_revealedTurns > 0) ...[
                  const SizedBox(height: 28),
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
                _RevealIn(
                  visible: _showScore,
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
                        _StatDeltaRow(label: 'SAVVY', value: totalScores.savvy),
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
                  visible: _showActions,
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
