import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A self-contained animated ring, no chart dependency required. Sweeps
/// from 0 to [score] out of [max] over the animation, and counts the
/// center number up alongside it.
class ScoreRing extends StatelessWidget {
  final int score;
  final int max;
  final Color color;
  final double size;

  const ScoreRing({
    super.key,
    required this.score,
    required this.color,
    this.max = 100,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped / max),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(progress: progress, color: color),
              ),
              Text(
                '${(progress * max).round()}',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 36),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
