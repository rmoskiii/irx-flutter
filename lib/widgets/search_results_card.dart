import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// Renders a "search_results" presentation inline in the transcript — a
/// results page for a query the player just ran.
///
/// This widget carries a specific argument, so it's built to look
/// *reassuring* rather than suspicious. A Companies House entry, two
/// decades of filings, a local paper quoting the man by name: the whole
/// point of The Prince is that a search corroborates the organisation and
/// says nothing about the correspondent. If this card looked sketchy the
/// scenario would give the answer away before the player made a decision.
///
/// So: no warning colours, no district accent on the results themselves,
/// no visual hierarchy implying which result matters. Result rows are
/// identical to each other, the way a real results page is. The only
/// accented element is the query chrome at the top, which tells the player
/// *they* ran this rather than that it was sent to them — the distinction
/// the entire scenario turns on.
class SearchResultsCard extends StatelessWidget {
  final DistrictTheme district;
  final String query;
  final List<Map<String, dynamic>> results;

  const SearchResultsCard({
    super.key,
    required this.district,
    required this.query,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: district.accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The search bar. Accented, because this is the part that says
            // "you went and looked" rather than "this arrived".
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: district.accent.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom:
                      BorderSide(color: district.accent.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 15, color: district.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: district.labelFont().copyWith(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < results.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),
                    ],
                    _ResultRow(
                      title: results[i]['title'] as String? ?? '',
                      url: results[i]['url'] as String? ?? '',
                      snippet: results[i]['snippet'] as String? ?? '',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One result. Title, then URL, then snippet — the order a real results
/// page uses, and the order a hurried player reads in. The URL sits
/// between them rather than under the snippet because the domain is
/// evidence the player is meant to be able to notice without being
/// prompted to; burying it would make the false tell unfair.
class _ResultRow extends StatelessWidget {
  final String title;
  final String url;
  final String snippet;

  const _ResultRow({
    required this.title,
    required this.url,
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                height: 1.35,
                color: const Color(0xFF9FC7FF),
              ),
        ),
        const SizedBox(height: 3),
        Text(
          url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          snippet,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}