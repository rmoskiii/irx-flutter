import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/mood_style.dart';

/// A procedural "living portrait" - no character art, but a soft glow,
/// a gradient-filled silhouette bust, a breathing pulse, and a handful of
/// drifting light particles, all driven by [MoodStyle]. The goal is a
/// premium, cinematic feel entirely from color, light and motion.
class SceneAvatar extends StatefulWidget {
  final String initial;
  final MoodStyle mood;
  final Color accent;
  final double size;

  const SceneAvatar({
    super.key,
    required this.initial,
    required this.mood,
    required this.accent,
    this.size = 96,
  });

  @override
  State<SceneAvatar> createState() => _SceneAvatarState();
}

class _SceneAvatarState extends State<SceneAvatar> with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    // Slower energy -> slower breathing. Clamp so even the calmest mood
    // still reads as alive, and the most restless doesn't strobe.
    final breathMs = (2400 - widget.mood.energy * 1400).round().clamp(900, 3200);
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: breathMs),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood;
    final glowSize = widget.size * 2.1;

    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow - a soft radial wash behind everything else,
          // breathing gently in sync with the silhouette.
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final t = _breathController.value;
              final scale = mood.baseScale * (1.0 + t * 0.08 * (0.4 + mood.energy));
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    mood.primary.withOpacity(0.35),
                    mood.secondary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Drifting light particles - small, slow, individually phased.
          ...List.generate(4, (i) => _FloatingParticle(
                controller: _particleController,
                index: i,
                radius: widget.size * 0.85,
                color: i.isEven ? mood.primary : mood.secondary,
              )),

          // The silhouette itself - a soft bust shape filled with the
          // mood gradient, breathing at a slightly smaller amplitude than
          // the glow so the two layers feel connected, not identical.
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final t = _breathController.value;
              final scale = mood.baseScale * (1.0 + t * 0.035 * (0.4 + mood.energy));
              return Transform.scale(scale: scale, child: child);
            },
            child: ClipPath(
              clipper: _BustSilhouetteClipper(),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [mood.primary, mood.secondary],
                  ),
                  border: Border.all(color: widget.accent.withOpacity(0.5), width: 1.4),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  widget.initial,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: widget.size * 0.28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drifts in a slow, individually-phased orbit around the avatar with a
/// gentle opacity pulse - the "cinematic dust" that makes the portrait
/// feel like it's sitting in a lit scene rather than floating on flat
/// color.
class _FloatingParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final double radius;
  final Color color;

  const _FloatingParticle({
    required this.controller,
    required this.index,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final phase = index * (pi / 2);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * pi + phase;
        final dx = cos(t) * radius;
        final dy = sin(t * 0.7) * radius * 0.6;
        final opacity = (sin(t * 1.3) + 1) / 2 * 0.6 + 0.1;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A simple rounded head-and-shoulders bust silhouette - abstract enough
/// to not need to resemble anyone specific, concrete enough to read
/// immediately as "a person" rather than just a blob.
class _BustSilhouetteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Head: a circle in the upper portion.
    final headRadius = w * 0.28;
    final headCenter = Offset(w / 2, h * 0.32);
    path.addOval(Rect.fromCircle(center: headCenter, radius: headRadius));

    // Shoulders: a rounded trapezoid rising from the bottom.
    final shoulderPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.12, h * 0.62, w * 0.34, h * 0.58)
      ..lineTo(w * 0.66, h * 0.58)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w * 0.88, h)
      ..close();

    return Path.combine(PathOperation.union, path, shoulderPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}