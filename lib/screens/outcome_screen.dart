import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/score_ring.dart';

class OutcomeScreen extends StatelessWidget {
  final DistrictTheme district;

  /// Sum of every turn's score delta across the whole playthrough, not
  /// just the final choice - so a 3-turn conversation shows credit (or
  /// blame) for the whole path, not only the last step.
  final StatDelta totalScores;
  final String consequence;
  final String outcomeExplanation;

  const OutcomeScreen({
    super.key,
    required this.district,
    required this.totalScores,
    required this.consequence,
    required this.outcomeExplanation,
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
    // display - the real signal is the per-stat breakdown below it.
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
                const SizedBox(height: 20),
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
