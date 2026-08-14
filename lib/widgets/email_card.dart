import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// Renders an "email" presentation inline in the transcript, in place of
/// the default chat bubble - reinforcing "you received an email" rather
/// than "you're chatting with someone." Deliberately the first thing a
/// new player ever sees, so this gets the most polish of any inline type.
class EmailCard extends StatelessWidget {
  final DistrictTheme district;
  final String sender;
  final String senderEmail;
  final String subject;
  final String body;

  const EmailCard({
    super.key,
    required this.district,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.body,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Icon(Icons.mail_outline_rounded,
                      size: 15, color: district.accent),
                  const SizedBox(width: 8),
                  Text(
                    'NEW MESSAGE',
                    style: district.labelFont().copyWith(
                          fontSize: 10,
                          letterSpacing: 1.0,
                          color: district.accent,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            district.accent.withValues(alpha: 0.15),
                        child: Text(
                          sender.isNotEmpty ? sender[0] : '?',
                          style:
                              TextStyle(color: district.accent, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sender,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              senderEmail,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
