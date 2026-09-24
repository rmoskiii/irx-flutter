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
  
  /// Whether this district plays in the full-screen cinematic shell — scene
  /// filling the phone, prose on a translucent panel, choices floating on the
  /// artwork — instead of the scrolling transcript.
  final bool usesCinematicShell;

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
    this.usesCinematicShell = false,
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
    backgroundGradient: const [
      Color(0xFF081410),
      Color(0xFF04211C),
      Color(0xFF02100D)
    ],
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
    backgroundGradient: const [
      Color(0xFF241608),
      Color(0xFF1C1006),
      Color(0xFF120A03)
    ],
    labelFont: () => GoogleFonts.dmSerifDisplay(fontStyle: FontStyle.italic),
    available: true,
    anchorScenarioId: 'the_secret',
  );

  /// Career reads institutional on purpose. Digital's teal is a signal in
  /// the dark and Neighbourhood's amber is a lit room; Career is fluorescent
  /// light on a Tuesday - cool, even, slightly airless. The steel blue is
  /// desaturated enough to sit next to the other two without competing, and
  /// the gradient is the only one in the app with no warmth in it at all.
  ///
  /// IBM Plex Sans over Space Grotesk for the same reason: it's the type
  /// of a form, a sign-off sheet, a review letter. The district's antagonist
  /// is partly an organisation, so the chrome should feel like one.
  static final career = DistrictTheme(
    id: 'career',
    name: 'Career District',
    tagline: 'Hold your ground when someone holds your job.',
    icon: Icons.badge_outlined,
    accent: const Color(0xFF7EA6DB),
    backgroundGradient: const [
      Color(0xFF0C121B),
      Color(0xFF101823),
      Color(0xFF070A0F)
    ],
    labelFont: () => GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w500),
    available: true,
    anchorScenarioId: 'the_instruction',
  );

  /// The Streets is the estate at night: the slate of scene.block's concrete
  /// under sodium light, with the wax-print red the cast wears as the one warm
  /// signal. Deliberately not Neighbourhood's amber - that is a lit room, and
  /// The Streets spends most of its week outside one.
  ///
  /// The accent is --irx-wax-red lifted until it reads on the dark gradient
  /// (the token itself is ~3:1 there). Oswald for the chrome: signage, not a
  /// form and not a novel.
  ///
  /// Without this entry `byId('streets')` fell back to Digital, so the
  /// scenario opened in Digital's teal and monospace. SPEC U06 §7 item 4.
  static final streets = DistrictTheme(
    id: 'streets',
    name: 'The Streets',
    tagline: 'Seven days on the estate. Nothing resets overnight.',
    icon: Icons.apartment_outlined,
    accent: const Color(0xFFE36A4A),
    backgroundGradient: const [
      Color(0xFF1A2029),
      Color(0xFF141920),
      Color(0xFF0B0E13)
    ],
    labelFont: () => GoogleFonts.oswald(fontWeight: FontWeight.w500),
    available: true,
    anchorScenarioId: 'the_streets',
    usesCinematicShell: true,
  );

  static final all = <DistrictTheme>[
    streets,
    neighborhood,
    digital,
    career,
  ];

  /// Looks up a district by its string id (matches the "district" field
  /// on a scenario) - used by the dev picker to theme a scenario it
  /// doesn't otherwise know about. Falls back to [digital] rather than
  /// throwing, since this only ever runs in debug tooling.
  static DistrictTheme byId(String id) {
    return all.firstWhere((d) => d.id == id, orElse: () => digital);
  }
}