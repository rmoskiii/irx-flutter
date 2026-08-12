import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// Renders an "sms" presentation inline in the transcript, in place of
/// the default chat bubble - reinforcing "you received a text" rather
/// than "you're chatting with someone." Sits in the same architectural
/// slot as [EmailCard]: same fade/rise entrance, same accent chrome,
/// different medium.
class SmsCard extends StatelessWidget {
  final DistrictTheme district;
  final String sender;
  final String senderNumber;
  final String body;

  const SmsCard({
    super.key,
    required this.district,
    required this.sender,
    required this.senderNumber,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    // System-y font for the sender/number strip - sells "this came from
    // the OS, not from a person you know."
    final chromeFont = GoogleFonts.inter();

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
          // Header strip - sender name + number, mimicking the way an
          // iOS/Android notification tops the message.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Icon(Icons.sms_outlined, size: 13, color: district.accent),
                const SizedBox(width: 6),
                Text(
                  sender,
                  style: chromeFont.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: district.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  senderNumber,
                  style: chromeFont.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // The message bubble itself - grey, left-aligned, generous
          // corner radius with the bottom-left corner squared off so it
          // reads unmistakably as "incoming SMS" rather than a generic
          // rounded card.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: district.accent.withOpacity(0.18)),
              ),
              child: Text(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}