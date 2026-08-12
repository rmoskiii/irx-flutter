import 'dart:async';
import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// Renders a "call" presentation as a modal styled like an active phone
/// call - large caller identity up top, a live-ticking call duration to
/// sell that this is a real conversation happening in real time, the
/// caller's opening line as the "what they're saying" panel, and the
/// response choices inside the modal itself.
///
/// Same architectural pattern as [PaymentRequestModal]: choices live IN
/// the modal, not after it. The decision to hang up, verify, or answer
/// belongs to this screen - a chat bubble underneath would break the
/// illusion that you're mid-call.
class CallModal extends StatefulWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;
  final String message;
  final List<ScenarioChoice> choices;

  const CallModal({
    super.key,
    required this.district,
    required this.data,
    required this.message,
    required this.choices,
  });

  @override
  State<CallModal> createState() => _CallModalState();
}

class _CallModalState extends State<CallModal> {
  late final Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedDuration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.data['callerName'] as String? ?? '';
    final callerRole = widget.data['callerRole'] as String? ?? '';
    final callerNumber = widget.data['callerNumber'] as String? ?? '';
    final status = widget.data['status'] as String? ?? 'On call';
    final district = widget.district;

    // Bound the modal to a fraction of the actual viewport rather than
    // assuming it always fits - a fixed-height Column with a live timer,
    // full caller identity block, and N choice buttons can easily exceed
    // a short or narrow window. Content beyond this scrolls instead of
    // overflowing.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: district.accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: district.accent.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: -6,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(color: district.accent),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                status.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: district.labelFont().copyWith(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      color: district.accent,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formattedDuration,
                        style: district.labelFont().copyWith(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: district.accent.withOpacity(0.15),
                            border: Border.all(color: district.accent.withOpacity(0.4)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            callerName.isNotEmpty ? callerName[0] : '?',
                            style: TextStyle(
                              color: district.accent,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          callerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          callerRole,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          callerNumber,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: district.labelFont().copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'HOW DO YOU RESPOND?',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 10),
                  for (final choice in widget.choices)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _CallChoiceButton(
                        label: choice.label,
                        district: district,
                        onTap: () => Navigator.of(context).pop(choice),
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

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.4 + 0.6 * _controller.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _controller.value),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CallChoiceButton extends StatelessWidget {
  final String label;
  final DistrictTheme district;
  final VoidCallback onTap;

  const _CallChoiceButton({
    required this.label,
    required this.district,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: district.accent.withOpacity(0.15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Shows the call as a barrier-dismissible-false modal. Resolves with
/// the [ScenarioChoice] the player tapped (or null if somehow dismissed
/// without one) - same contract as [showPaymentRequestModal].
Future<ScenarioChoice?> showCallModal(
  BuildContext context, {
  required DistrictTheme district,
  required Map<String, dynamic> data,
  required String message,
  required List<ScenarioChoice> choices,
}) {
  return showDialog<ScenarioChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) => CallModal(
      district: district,
      data: data,
      message: message,
      choices: choices,
    ),
  );
}