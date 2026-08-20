import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

class WorkArtifactCard extends StatelessWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;
  final String body;
  final bool animate;

  const WorkArtifactCard({
    super.key,
    required this.district,
    required this.data,
    required this.body,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final variant = data['variant'] as String? ?? 'record';
    final title = data['title'] as String? ?? _titleFor(variant);
    final eyebrow = data['eyebrow'] as String? ?? _eyebrowFor(variant);
    final status = data['status'] as String? ?? '';
    final fields = ((data['fields'] as List?) ?? const [])
        .whereType<Map>()
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
    final actions = ((data['actions'] as List?) ?? const [])
        .whereType<String>()
        .where((a) => a.trim().isNotEmpty)
        .toList();
    final accent = _accentFor(variant, district);

    final card = Container(
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.surfaceRaised, accent, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ArtifactHeader(
            district: district,
            accent: accent,
            icon: _iconFor(variant),
            eyebrow: eyebrow,
            status: status,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16),
                ),
                if (fields.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FieldGrid(fields: fields, accent: accent),
                ],
                if (body.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ArtifactBody(text: body),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in actions)
                        _ActionPill(label: action, accent: accent),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!animate) return card;

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
      child: card,
    );
  }
}

class _ArtifactHeader extends StatelessWidget {
  final DistrictTheme district;
  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String status;

  const _ArtifactHeader({
    required this.district,
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border:
            Border(bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              eyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: district.labelFont().copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: accent,
                  ),
            ),
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(Colors.white, accent, 0.35),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final Color accent;

  const _FieldGrid({required this.fields, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++)
            _FieldRow(
              label: fields[i]['label'] as String? ?? '',
              value: fields[i]['value'] as String? ?? '',
              accent: accent,
              showBorder: i != fields.length - 1,
            ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool showBorder;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactBody extends StatelessWidget {
  final String text;

  const _ArtifactBody({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _ActionPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

String _titleFor(String variant) {
  switch (variant) {
    case 'qa_checklist':
      return 'QA Checklist';
    case 'file_upload':
      return 'Upload Record';
    case 'review_notice':
      return 'Delivery Assurance Review';
    case 'chronology':
      return 'Contemporaneous Chronology';
    case 'email_draft':
      return 'Client Email Draft';
    default:
      return 'Work Record';
  }
}

String _eyebrowFor(String variant) {
  switch (variant) {
    case 'qa_checklist':
      return 'Internal checklist';
    case 'file_upload':
      return 'Document system';
    case 'review_notice':
      return 'Review notice';
    case 'chronology':
      return 'Evidence record';
    case 'email_draft':
      return 'Draft from your account';
    default:
      return 'Northstar record';
  }
}

IconData _iconFor(String variant) {
  switch (variant) {
    case 'qa_checklist':
      return Icons.fact_check_outlined;
    case 'file_upload':
      return Icons.upload_file_outlined;
    case 'review_notice':
      return Icons.policy_outlined;
    case 'chronology':
      return Icons.format_list_numbered_outlined;
    case 'email_draft':
      return Icons.forward_to_inbox_outlined;
    default:
      return Icons.description_outlined;
  }
}

Color _accentFor(String variant, DistrictTheme district) {
  switch (variant) {
    case 'review_notice':
      return const Color(0xFFC9D3DF);
    case 'chronology':
      return const Color(0xFF9DD6B5);
    case 'email_draft':
      return const Color(0xFFAFC7F0);
    case 'qa_checklist':
      return const Color(0xFFFFC15E);
    default:
      return district.accent;
  }
}
