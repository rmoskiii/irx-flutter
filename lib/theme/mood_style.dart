import 'package:flutter/material.dart';

/// Every visual/motion decision a "scene" beat makes is driven by one of
/// these. No facial rendering, no character art - the mood is carried
/// entirely by gradient color and animation character (how fast it
/// pulses, how much it drifts). Deliberately procedural rather than
/// illustrated, so adding a new mood later is a palette entry, not an
/// asset commission.
class MoodStyle {
  final Color primary;
  final Color secondary;

  /// 0.0 (barely moving, heavy) to 1.0 (fast, restless) - drives pulse
  /// speed and particle drift speed together, so a mood's "energy" reads
  /// consistently across every animated element.
  final double energy;

  /// Slight scale modifier - some moods should feel smaller/shrunk
  /// (sheepish) or larger/expansive (excited) even before any animation.
  final double baseScale;

  const MoodStyle({
    required this.primary,
    required this.secondary,
    required this.energy,
    this.baseScale = 1.0,
  });
}

class MoodPalette {
  MoodPalette._();

  static const Map<String, MoodStyle> _moods = {
    'anxious': MoodStyle(
      primary: Color(0xFFFFB020),
      secondary: Color(0xFFFF6B4A),
      energy: 0.8,
    ),
    'pleading': MoodStyle(
      primary: Color(0xFF8C6BFF),
      secondary: Color(0xFF4A6BFF),
      energy: 0.35,
      baseScale: 1.05,
    ),
    'excited': MoodStyle(
      primary: Color(0xFFFFD24A),
      secondary: Color(0xFFFF9F4A),
      energy: 0.9,
      baseScale: 1.08,
    ),
    'hurt': MoodStyle(
      primary: Color(0xFFFF5C7A),
      secondary: Color(0xFF7A1F35),
      energy: 0.2,
    ),
    'distracted': MoodStyle(
      primary: Color(0xFF9AA0A6),
      secondary: Color(0xFF6B7280),
      energy: 0.5,
      baseScale: 0.95,
    ),
    'relieved': MoodStyle(
      primary: Color(0xFF5EE6A0),
      secondary: Color(0xFF2E9E6E),
      energy: 0.3,
    ),
    'cold': MoodStyle(
      primary: Color(0xFF7FD1E8),
      secondary: Color(0xFF3E6E82),
      energy: 0.15,
      baseScale: 0.97,
    ),
    'sheepish': MoodStyle(
      primary: Color(0xFFF4A6C1),
      secondary: Color(0xFFC97B98),
      energy: 0.25,
      baseScale: 0.92,
    ),
  };

  static const MoodStyle _fallback = MoodStyle(
    primary: Color(0xFFB78CFF),
    secondary: Color(0xFF6B4AFF),
    energy: 0.4,
  );

  static MoodStyle of(String mood) => _moods[mood.toLowerCase()] ?? _fallback;
}