import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

/// Renders a "payment_request" presentation as a slick fake-fintech modal -
/// crisp, dark, and confident-looking on purpose. This is the moment the
/// entire scam exists to produce, so it gets the same dramatic weight as
/// the document reveal, just a different visual language: this is what
/// convincing looks like, not what suspicious looks like.
///
/// Unlike the document modal, the response choices live INSIDE this modal
/// rather than being revealed after it closes - the decision belongs to
/// this screen, not to a separate chat bubble underneath it.
class PaymentRequestModal extends StatefulWidget {
  final DistrictTheme district;
  final Map<String, dynamic> data;
  final List<ScenarioChoice> choices;

  const PaymentRequestModal({
    super.key,
    required this.district,
    required this.data,
    required this.choices,
  });

  @override
  State<PaymentRequestModal> createState() => _PaymentRequestModalState();
}

class _PaymentRequestModalState extends State<PaymentRequestModal> {
  static const _revealDuration = Duration(milliseconds: 320);
  static const _choiceStaggerDelay = Duration(milliseconds: 95);
  static const _choiceCommitDelay = Duration(milliseconds: 140);

  int _visibleChoiceCount = 0;
  String? _selectedChoiceId;

  bool get _choicesLocked => _selectedChoiceId != null;

  @override
  void initState() {
    super.initState();
    _revealChoices();
  }

  Future<void> _revealChoices() async {
    await Future.delayed(_revealDuration);
    for (var i = 0; i < widget.choices.length; i++) {
      await Future.delayed(_choiceStaggerDelay);
      if (!mounted || _selectedChoiceId != null) return;
      setState(() => _visibleChoiceCount = i + 1);
    }
  }

  Future<void> _selectChoice(ScenarioChoice choice) async {
    if (_choicesLocked) return;
    setState(() => _selectedChoiceId = choice.id);
    await Future.delayed(_choiceCommitDelay);
    if (!mounted) return;
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final payee = widget.data['payee'] as String? ?? '';
    final amount = widget.data['amount'] as String? ?? '';
    final reference = widget.data['reference'] as String? ?? '';
    final note = widget.data['note'] as String? ?? '';
    final district = widget.district;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: _revealDuration,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 14, color: district.accent),
                    const SizedBox(width: 6),
                    Text(
                      'PAYMENT REQUEST',
                      style: district.labelFont().copyWith(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: district.accent,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  amount,
                  style: district.labelFont().copyWith(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'requested by',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
                Text(
                  payee,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                _DetailRow(
                    label: 'Reference', value: reference, district: district),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.amber.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_visibleChoiceCount > 0) ...[
                  const SizedBox(height: 22),
                  Text(
                    'HOW DO YOU RESPOND?',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 10),
                  // Deliberately identical styling for every option - nothing
                  // here should hint which response is the "right" one.
                  for (final choice in widget.choices.take(_visibleChoiceCount))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('payment-choice-${choice.id}'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 8),
                            child: child,
                          ),
                        ),
                        child: _PaymentChoiceButton(
                          label: choice.label,
                          district: district,
                          disabled: _selectedChoiceId != null,
                          selected: _selectedChoiceId == choice.id,
                          onTap: () => _selectChoice(choice),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentChoiceButton extends StatelessWidget {
  final String label;
  final DistrictTheme district;
  final bool disabled;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChoiceButton({
    required this.label,
    required this.district,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? district.accent.withOpacity(0.16)
          : Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: district.accent.withOpacity(0.15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? district.accent.withOpacity(0.65)
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Opacity(
            opacity: disabled && !selected ? 0.42 : 1,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final DistrictTheme district;

  const _DetailRow(
      {required this.label, required this.value, required this.district});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        Text(
          value,
          style: district
              .labelFont()
              .copyWith(fontSize: 12, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Shows the payment request as a barrier-dismissible-false modal. Unlike
/// [showDocumentModal], this resolves with the [ScenarioChoice] the player
/// tapped (or null if somehow dismissed without one) - the response is
/// made from inside the modal, not after it.
Future<ScenarioChoice?> showPaymentRequestModal(
  BuildContext context, {
  required DistrictTheme district,
  required Map<String, dynamic> data,
  required List<ScenarioChoice> choices,
}) {
  return showDialog<ScenarioChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) =>
        PaymentRequestModal(district: district, data: data, choices: choices),
  );
}
