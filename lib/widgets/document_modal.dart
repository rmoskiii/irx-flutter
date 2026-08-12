import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/district_theme.dart';

/// Renders a "document" presentation as a full-screen modal styled like a
/// physical letterhead - deliberately breaking from the app's dark theme,
/// since a stark cream document appearing out of the dark UI is exactly
/// the jolt this beat is meant to create. Call via [showDocumentModal].
class DocumentModal extends StatelessWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;

  const DocumentModal({super.key, required this.district, required this.data});

  @override
  Widget build(BuildContext context) {
    final sender = data['sender'] as String? ?? '';
    final title = data['letterheadTitle'] as String? ?? '';
    final reference = data['reference'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final serif = GoogleFonts.dmSerifDisplay();
    final letterBody = GoogleFonts.newsreader();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Material(
            color: const Color(0xFFF6F1E7),
            borderRadius: BorderRadius.circular(4),
            elevation: 24,
            shadowColor: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sender.toUpperCase(),
                    style: serif.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF2A2A28),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: const Color(0xFFB8AE96)),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: serif.copyWith(fontSize: 20, color: const Color(0xFF1A1A18)),
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      style: letterBody.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF6B6456),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        body,
                        style: letterBody.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          color: const Color(0xFF2A2A28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A18),
                        backgroundColor: district.accent.withOpacity(0.16),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close document'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the document as a barrier-dismissible-false modal (the player has
/// to explicitly close it) and resolves once dismissed - so callers can
/// await it before revealing the next set of choices.
Future<void> showDocumentModal(
  BuildContext context, {
  required DistrictTheme district,
  required Map<String, dynamic> data,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) => DocumentModal(district: district, data: data),
  );
}