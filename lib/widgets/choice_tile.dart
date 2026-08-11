import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';

class ChoiceTile extends StatefulWidget {
  final String label;
  final DistrictTheme district;
  final bool disabled;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.label,
    required this.district,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<ChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.disabled ? null : () => setState(() => _pressed = false),
      onTapUp: widget.disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? widget.district.accent.withOpacity(0.6)
                  : AppColors.border,
            ),
          ),
          child: Opacity(
            opacity: widget.disabled ? 0.4 : 1,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
