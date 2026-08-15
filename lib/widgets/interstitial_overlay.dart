import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/district_theme.dart';

/// A time-stamp card — "Three weeks later" — held over a darkened screen
/// before a node reveals. Auto-dismisses after [duration]; a tap skips it
/// early and reveals the node rather than advancing past it.
///
/// This is the only thing standing between a delayed consequence and it
/// reading as the next sentence of the same conversation, so it gets the
/// screen to itself for two seconds and no chrome at all.
Future<void> showInterstitial(
  BuildContext context, {
  required DistrictTheme district,
  required String label,
  Duration duration = const Duration(milliseconds: 2000),
}) {
  if (label.trim().isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    pageBuilder: (_, __, ___) => _InterstitialCard(
      district: district,
      label: label,
      duration: duration,
    ),
  );
}

class _InterstitialCard extends StatefulWidget {
  final DistrictTheme district;
  final String label;
  final Duration duration;

  const _InterstitialCard({
    required this.district,
    required this.label,
    required this.duration,
  });

  @override
  State<_InterstitialCard> createState() => _InterstitialCardState();
}

class _InterstitialCardState extends State<_InterstitialCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.district.accent;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: widget.district.labelFont().copyWith(
                      fontSize: 17,
                      height: 1.4,
                      letterSpacing: 0.4,
                      color: accent.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 36,
                height: 1,
                color: accent.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}