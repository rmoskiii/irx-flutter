import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

const Map<String, String> _statLabels = {
  'savvy': 'SAVVY',
  'streetSmarts': 'STREET SMARTS',
  'integrity': 'INTEGRITY',
};

const Map<String, IconData> _statIcons = {
  'savvy': Icons.psychology_outlined,
  'streetSmarts': Icons.bolt_outlined,
  'integrity': Icons.balance_outlined,
};

/// Shows exactly which stats moved on a turn and why - the core of the
/// "transparent evaluation" goal. Only stats with both a non-zero delta
/// and a reason are rendered, so a turn that only touched one stat
/// doesn't show two blank rows either. Reused unmodified on both the
/// inline transcript note and the outcome screen's full breakdown, so the
/// visual language for "here's why" stays identical everywhere it appears.
class ScoreFeedback extends StatelessWidget {
  final StatDelta scores;
  final Map<String, String> reasons;
  final DistrictTheme district;
  final bool compact;

  const ScoreFeedback({
    super.key,
    required this.scores,
    required this.reasons,
    required this.district,
    this.compact = false,
  });

  Map<String, int> get _deltasByStat => {
        'savvy': scores.savvy,
        'streetSmarts': scores.streetSmarts,
        'integrity': scores.integrity,
      };

  @override
  Widget build(BuildContext context) {
    final rows = _deltasByStat.entries
        .where((e) => e.value != 0 && reasons.containsKey(e.key))
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      margin: EdgeInsets.only(top: compact ? 6 : 0, bottom: compact ? 0 : 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _FeedbackRow(
              statKey: rows[i].key,
              delta: rows[i].value,
              reason: rows[i].value == 0 ? '' : reasons[rows[i].key]!,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final String statKey;
  final int delta;
  final String reason;
  final bool compact;

  const _FeedbackRow({
    required this.statKey,
    required this.delta,
    required this.reason,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color = positive ? AppColors.success : AppColors.danger;
    final label = _statLabels[statKey] ?? statKey;
    final icon = _statIcons[statKey] ?? Icons.circle_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: compact ? 13 : 15, color: color),
            const SizedBox(width: 6),
            Text(
              '$label ${positive ? '+' : ''}$delta',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: compact ? 11 : 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: EdgeInsets.only(left: compact ? 19 : 21),
          child: Text(
            reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 12 : 13,
                ),
          ),
        ),
      ],
    );
  }
}