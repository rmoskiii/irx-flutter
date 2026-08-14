import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

class PersonaBubble extends StatelessWidget {
  final DistrictTheme district;
  final String name;
  final String role;
  final String message;

  /// Only the first message in a conversation shows the avatar/name/role
  /// header - later turns just show the bubble, so a multi-turn
  /// conversation doesn't repeat "Adewale Okoro, Legal Representative"
  /// four times in a row.
  final bool showHeader;

  const PersonaBubble({
    super.key,
    required this.district,
    required this.name,
    required this.role,
    required this.message,
    this.showHeader = true,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: district.accent.withValues(alpha: 0.15),
                  child: Icon(Icons.person_outline,
                      size: 16, color: district.accent),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    Text(role,
                        style: district.labelFont().copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(16).copyWith(
                topLeft: const Radius.circular(4),
              ),
              border: Border.all(color: district.accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              message,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
