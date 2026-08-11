import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every district gets one of these. The app shell (nav bar, stat pills,
/// outcome layout) never changes - only the accent color, background
/// gradient, and type treatment inside a district's own screens change.
/// This is how the app reads as "distinct worlds" without needing a
/// full redesign per district.
class DistrictTheme {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color accent;
  final List<Color> backgroundGradient;
  final TextStyle Function() labelFont;
  final bool available;

  const DistrictTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.backgroundGradient,
    required this.labelFont,
    this.available = false,
  });
}

class Districts {
  Districts._();

  static final digital = DistrictTheme(
    id: 'digital',
    name: 'Digital District',
    tagline: 'Spot the scam before it spots you',
    icon: Icons.terminal_rounded,
    accent: const Color(0xFF5EE6D0),
    backgroundGradient: const [Color(0xFF081410), Color(0xFF04211C), Color(0xFF02100D)],
    labelFont: () => GoogleFonts.spaceMono(),
    available: true,
  );

  static final neighborhood = DistrictTheme(
    id: 'neighborhood',
    name: 'Neighborhood District',
    tagline: 'Real people. Real choices. Real weight.',
    icon: Icons.night_shelter_outlined,
    accent: const Color(0xFFFFC15E),
    backgroundGradient: const [Color(0xFF241608), Color(0xFF1C1006), Color(0xFF120A03)],
    labelFont: () => GoogleFonts.dmSerifDisplay(fontStyle: FontStyle.italic),
  );

  static final money = DistrictTheme(
    id: 'money',
    name: 'Money District',
    tagline: 'Unlocks once judgment earns it',
    icon: Icons.account_balance_outlined,
    accent: const Color(0xFF8A8A90),
    backgroundGradient: const [Color(0xFF141416), Color(0xFF101012), Color(0xFF0B0B0C)],
    labelFont: () => GoogleFonts.spaceGrotesk(),
  );

  static final career = DistrictTheme(
    id: 'career',
    name: 'Career District',
    tagline: 'Unlocks once judgment earns it',
    icon: Icons.badge_outlined,
    accent: const Color(0xFF8A8A90),
    backgroundGradient: const [Color(0xFF141416), Color(0xFF101012), Color(0xFF0B0B0C)],
    labelFont: () => GoogleFonts.spaceGrotesk(),
  );

  static final all = <DistrictTheme>[digital, neighborhood, money, career];
}
