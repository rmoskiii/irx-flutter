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

  /// Optional path to a real illustrated asset (e.g. 'assets/districts/
  /// digital.png'), added via pubspec.yaml's flutter/assets list. When
  /// set, DistrictCard renders it as the backdrop. When null (true for
  /// every district today - no art pipeline exists yet), DistrictCard
  /// falls back to a procedural glow-and-silhouette backdrop built from
  /// this theme's own accent/icon, so cards still look considered without
  /// needing commissioned art. Drop in a real asset later and the card
  /// picks it up with no other code changes.
  final String? imagePath;

  /// The scenario id this district opens into when tapped from the home
  /// hub - e.g. "the_prince" for Digital, "the_secret" for Neighbourhood.
  /// Without this, tapping any district card would fall back to the
  /// backend's single default scenario regardless of which district was
  /// actually tapped.
  final String? anchorScenarioId;

  const DistrictTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.backgroundGradient,
    required this.labelFont,
    this.available = false,
    this.imagePath,
    this.anchorScenarioId,
  });
}

class Districts {
  Districts._();

  static final digital = DistrictTheme(
    id: 'digital',
    name: 'Digital District',
    tagline: 'Spot scams. Outsmart online threats.',
    icon: Icons.terminal_rounded,
    accent: const Color(0xFF5EE6D0),
    backgroundGradient: const [Color(0xFF081410), Color(0xFF04211C), Color(0xFF02100D)],
    labelFont: () => GoogleFonts.spaceMono(),
    available: true,
    anchorScenarioId: 'the_prince',
  );

  static final neighborhood = DistrictTheme(
    id: 'neighborhood',
    name: 'Neighborhood District',
    tagline: 'Real people. Real choices. Real weight.',
    icon: Icons.night_shelter_outlined,
    accent: const Color(0xFFFFC15E),
    backgroundGradient: const [Color(0xFF241608), Color(0xFF1C1006), Color(0xFF120A03)],
    labelFont: () => GoogleFonts.dmSerifDisplay(fontStyle: FontStyle.italic),
    available: true,
    anchorScenarioId: 'the_secret',
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

  /// Looks up a district by its string id (matches the "district" field
  /// on a scenario) - used by the dev picker to theme a scenario it
  /// doesn't otherwise know about. Falls back to [digital] rather than
  /// throwing, since this only ever runs in debug tooling.
  static DistrictTheme byId(String id) {
    return all.firstWhere((d) => d.id == id, orElse: () => digital);
  }
}