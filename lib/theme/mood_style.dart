import 'package:flutter/material.dart';

class MoodStyle {
  final Color primary;
  final Color secondary;
  final double energy;
  final double baseScale;
  final double atmosphereOpacity;
  final double atmosphereBlur;
  final double atmosphereBrightness;

  const MoodStyle({
    required this.primary,
    required this.secondary,
    required this.energy,
    this.baseScale = 1.0,
    this.atmosphereOpacity = 0.55,
    this.atmosphereBlur = 70,
    this.atmosphereBrightness = 0.04,
  });
}

class MoodPalette {
  MoodPalette._();

  static const Map<String, MoodStyle> _moods = {
    'anxious': MoodStyle(
      primary: Color(0xFFFFB020),
      secondary: Color(0xFFFF6B4A),
      energy: 0.8,
      atmosphereOpacity: 0.6,
      atmosphereBlur: 55,
      atmosphereBrightness: 0.03,
    ),
    'pleading': MoodStyle(
      primary: Color(0xFF8C6BFF),
      secondary: Color(0xFF4A6BFF),
      energy: 0.35,
      baseScale: 1.05,
      atmosphereOpacity: 0.65,
      atmosphereBlur: 80,
      atmosphereBrightness: 0.05,
    ),
    'excited': MoodStyle(
      primary: Color(0xFFFFD24A),
      secondary: Color(0xFFFF9F4A),
      energy: 0.9,
      baseScale: 1.08,
      atmosphereOpacity: 0.7,
      atmosphereBlur: 60,
      atmosphereBrightness: 0.08,
    ),
    'hurt': MoodStyle(
      primary: Color(0xFFFF5C7A),
      secondary: Color(0xFF7A1F35),
      energy: 0.2,
      atmosphereOpacity: 0.4,
      atmosphereBlur: 90,
      atmosphereBrightness: 0.02,
    ),
    'distracted': MoodStyle(
      primary: Color(0xFF9AA0A6),
      secondary: Color(0xFF6B7280),
      energy: 0.5,
      baseScale: 0.95,
      atmosphereOpacity: 0.35,
      atmosphereBlur: 80,
      atmosphereBrightness: 0.03,
    ),
    'relieved': MoodStyle(
      primary: Color(0xFF5EE6A0),
      secondary: Color(0xFF2E9E6E),
      energy: 0.3,
      atmosphereOpacity: 0.55,
      atmosphereBlur: 85,
      atmosphereBrightness: 0.07,
    ),
    'cold': MoodStyle(
      primary: Color(0xFF7FD1E8),
      secondary: Color(0xFF3E6E82),
      energy: 0.15,
      baseScale: 0.97,
      atmosphereOpacity: 0.3,
      atmosphereBlur: 95,
      atmosphereBrightness: 0.02,
    ),
    'sheepish': MoodStyle(
      primary: Color(0xFFF4A6C1),
      secondary: Color(0xFFC97B98),
      energy: 0.25,
      baseScale: 0.92,
      atmosphereOpacity: 0.45,
      atmosphereBlur: 80,
      atmosphereBrightness: 0.05,
    ),
    'reflective': MoodStyle(
      primary: Color(0xFF9DB4D4),
      secondary: Color(0xFF5A7BA6),
      energy: 0.2,
      atmosphereOpacity: 0.45,
      atmosphereBlur: 85,
      atmosphereBrightness: 0.05,
    ),
    'warm': MoodStyle(
      primary: Color(0xFFFFBD6B),
      secondary: Color(0xFFE89540),
      energy: 0.3,
      baseScale: 1.03,
      atmosphereOpacity: 0.55,
      atmosphereBlur: 80,
      atmosphereBrightness: 0.08,
    ),
    'thoughtful': MoodStyle(
      primary: Color(0xFFA8B8CC),
      secondary: Color(0xFF6E82A0),
      energy: 0.15,
      atmosphereOpacity: 0.4,
      atmosphereBlur: 90,
      atmosphereBrightness: 0.04,
    ),
    'open': MoodStyle(
      primary: Color(0xFF7ED6A8),
      secondary: Color(0xFF4AAE7A),
      energy: 0.35,
      baseScale: 1.04,
      atmosphereOpacity: 0.5,
      atmosphereBlur: 75,
      atmosphereBrightness: 0.07,
    ),
    'vulnerable': MoodStyle(
      primary: Color(0xFFD4A0C4),
      secondary: Color(0xFF8E5A7E),
      energy: 0.15,
      baseScale: 0.95,
      atmosphereOpacity: 0.4,
      atmosphereBlur: 90,
      atmosphereBrightness: 0.03,
    ),
    'tired': MoodStyle(
      primary: Color(0xFF8A8FA6),
      secondary: Color(0xFF5C6178),
      energy: 0.1,
      baseScale: 0.94,
      atmosphereOpacity: 0.3,
      atmosphereBlur: 95,
      atmosphereBrightness: 0.02,
    ),
    'casual': MoodStyle(
      primary: Color(0xFFB0B8C4),
      secondary: Color(0xFF7A8494),
      energy: 0.4,
      atmosphereOpacity: 0.35,
      atmosphereBlur: 75,
      atmosphereBrightness: 0.05,
    ),
    'alert': MoodStyle(
      primary: Color(0xFFFFD24A),
      secondary: Color(0xFFFF6B4A),
      energy: 0.75,
      baseScale: 1.04,
      atmosphereOpacity: 0.62,
      atmosphereBlur: 60,
      atmosphereBrightness: 0.05,
    ),
    'frightened': MoodStyle(
      primary: Color(0xFFFF8A8A),
      secondary: Color(0xFF5B2436),
      energy: 0.55,
      baseScale: 0.96,
      atmosphereOpacity: 0.5,
      atmosphereBlur: 90,
      atmosphereBrightness: 0.02,
    ),
    'defensive': MoodStyle(
      primary: Color(0xFFFF9F5A),
      secondary: Color(0xFF8A3C23),
      energy: 0.65,
      atmosphereOpacity: 0.55,
      atmosphereBlur: 70,
      atmosphereBrightness: 0.04,
    ),
    'devastated': MoodStyle(
      primary: Color(0xFFFF6B8A),
      secondary: Color(0xFF381622),
      energy: 0.12,
      baseScale: 0.9,
      atmosphereOpacity: 0.38,
      atmosphereBlur: 105,
      atmosphereBrightness: 0.01,
    ),
    'hollow': MoodStyle(
      primary: Color(0xFF8A90A6),
      secondary: Color(0xFF262A36),
      energy: 0.05,
      baseScale: 0.9,
      atmosphereOpacity: 0.25,
      atmosphereBlur: 110,
      atmosphereBrightness: 0.01,
    ),
    'happy': MoodStyle(
      primary: Color(0xFFFFD86B),
      secondary: Color(0xFFFF7D7D),
      energy: 0.85,
      baseScale: 1.08,
      atmosphereOpacity: 0.68,
      atmosphereBlur: 58,
      atmosphereBrightness: 0.08,
    ),
    'procedural': MoodStyle(
      primary: Color(0xFFA7C4E8),
      secondary: Color(0xFF4F6178),
      energy: 0.18,
      baseScale: 0.98,
      atmosphereOpacity: 0.32,
      atmosphereBlur: 88,
      atmosphereBrightness: 0.03,
    ),
    'pressed': MoodStyle(
      primary: Color(0xFFFFC15E),
      secondary: Color(0xFF7EA6DB),
      energy: 0.68,
      atmosphereOpacity: 0.56,
      atmosphereBlur: 64,
      atmosphereBrightness: 0.04,
    ),
    'immovable': MoodStyle(
      primary: Color(0xFFC9D3DF),
      secondary: Color(0xFF3C4654),
      energy: 0.08,
      baseScale: 0.96,
      atmosphereOpacity: 0.28,
      atmosphereBlur: 98,
      atmosphereBrightness: 0.02,
    ),
  };

  static const MoodStyle _fallback = MoodStyle(
    primary: Color(0xFFB78CFF),
    secondary: Color(0xFF6B4AFF),
    energy: 0.4,
  );

  /// Authored moods that map onto an existing style rather than earning
  /// their own. Keeps the palette small while letting scenarios use the
  /// word that fits the beat.
  static const Map<String, String> _aliases = {
    'easy': 'casual',
    'conceding': 'sheepish',
    'careful': 'thoughtful',
    'neutral': 'thoughtful',
    'distant': 'cold',
    'polite': 'cold',
    'flat': 'tired',
    'withdrawn': 'vulnerable',
    'gone': 'hollow',
    'searching': 'reflective',
    'exhausted': 'tired',
    'deflated': 'hurt',
    'alarmed': 'alert',
    'unreadable': 'cold',
    'quiet': 'thoughtful',
    'unknown': 'distracted',
    'raw': 'vulnerable',
  };

  static MoodStyle of(String mood) {
    final key = mood.toLowerCase();
    return _moods[key] ?? _moods[_aliases[key] ?? ''] ?? _fallback;
  }
}
