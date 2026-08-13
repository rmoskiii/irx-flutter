import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/score_feedback.dart';
import '../widgets/score_ring.dart';
import 'scenario_screen.dart';

class OutcomeScreen extends StatelessWidget {
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

  String get _headline {
    final total = totalScores.total;
    if (total >= 60) return 'Excellent judgment.';
    if (total >= 25) return 'Good call.';
    if (total >= 0) return 'You got through it.';
    return 'That one stung.';
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
                ScoreRing(score: displayScore, color: district.accent),
                const SizedBox(height: 16),
                Text(_headline, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    consequence,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 28),
                if (breakdown.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HOW WE GOT HERE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final turn in breakdown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TOTALS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _StatDeltaRow(label: 'SAVVY', value: totalScores.savvy),
                _StatDeltaRow(label: 'INTEGRITY', value: totalScores.integrity),
                _StatDeltaRow(label: 'STREET SMARTS', value: totalScores.streetSmarts),
                const SizedBox(height: 24),
                Text(
                  outcomeExplanation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
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
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: district.accent.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ScenarioScreen(
                          district: district,
                          scenarioIdOverride: scenarioId,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}