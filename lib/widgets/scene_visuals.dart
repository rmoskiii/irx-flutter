import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../theme/mood_style.dart';

/// Parsed form of a node's `presentation.data.visual` block.
///
/// [setting] and the icon/colour pair derived from it are what actually
/// drive the rendered plate. [props] is deliberately NOT rendered — it's
/// authoring vocabulary describing the concrete objects in the beat, kept
/// so a future illustration/silhouette layer has something to work from.
/// Rendering it as text turns a lookup table into UI copy, which is what
/// it used to do. Don't put it back on screen.
class SceneVisualStyle {
  final String setting;
  final String pressure;

  /// Authored (or inferred) object anchors for this beat. Data only.
  final List<String> props;

  final IconData icon;
  final List<Color> colors;

  const SceneVisualStyle({
    required this.setting,
    required this.pressure,
    required this.props,
    required this.icon,
    required this.colors,
  });

  factory SceneVisualStyle.fromData(
    DistrictTheme district,
    Map<String, dynamic> data,
  ) {
    final visual = data['visual'] as Map<String, dynamic>? ?? const {};
    final location = data['location'] as String? ?? '';
    final setting = (visual['setting'] as String?) ?? _inferSetting(location);
    final pressure = visual['pressure'] as String? ?? '';
    final authoredProps = (visual['props'] as List?)
            ?.whereType<String>()
            .where((p) => p.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final props = authoredProps.isNotEmpty ? authoredProps : _propsFor(setting);

    return SceneVisualStyle(
      setting: setting,
      pressure: pressure,
      props: props,
      icon: _iconFor(setting),
      colors: _colorsFor(setting, district),
    );
  }
}

String _inferSetting(String location) {
  final lower = location.toLowerCase();
  if (lower.contains('kitchen')) return 'kitchen';
  if (lower.contains('coffee')) return 'coffee_shop';
  if (lower.contains('party')) return 'party';
  if (lower.contains('street') || lower.contains('outside')) return 'street';
  if (lower.contains('flat')) return 'flat';
  if (lower.contains('phone')) return 'phone';
  if (lower.contains('desk')) return 'desk';
  if (lower.contains('meeting')) return 'meeting_room';
  if (lower.contains('dana')) return 'review_room';
  if (lower.contains('office')) return 'office';
  return 'scene';
}

IconData _iconFor(String setting) {
  switch (setting) {
    case 'kitchen':
      return Icons.countertops_outlined;
    case 'coffee_shop':
      return Icons.local_cafe_outlined;
    case 'party':
      return Icons.celebration_outlined;
    case 'street':
      return Icons.directions_walk_outlined;
    case 'flat':
      return Icons.weekend_outlined;
    case 'phone':
      return Icons.phone_iphone_outlined;
    case 'desk':
      return Icons.desktop_windows_outlined;
    case 'meeting_room':
      return Icons.meeting_room_outlined;
    case 'review_room':
      return Icons.account_balance_outlined;
    case 'office':
      return Icons.business_center_outlined;
    default:
      return Icons.place_outlined;
  }
}

/// Fallback object anchors for a setting when a node authors no `props`.
/// Data only — see the note on [SceneVisualStyle.props]. These are the
/// values that used to leak on screen as "CURSOR / TIMESTAMP / UPLOAD".
List<String> _propsFor(String setting) {
  switch (setting) {
    case 'kitchen':
      return const ['glasses', 'tea towel', 'counter'];
    case 'coffee_shop':
      return const ['coffee', 'noise', 'small table'];
    case 'party':
      return const ['ring', 'toast', 'music'];
    case 'street':
      return const ['cold air', 'phone', 'pavement'];
    case 'flat':
      return const ['sofa', 'hallway', 'quiet'];
    case 'phone':
      return const ['screen', 'typing', 'silence'];
    case 'desk':
      return const ['cursor', 'timestamp', 'upload'];
    case 'meeting_room':
      return const ['checklist', 'laptop', 'closed door'];
    case 'review_room':
      return const ['notes', 'timeline', 'process'];
    case 'office':
      return const ['corridor', 'absence', 'record'];
    default:
      return const [];
  }
}

List<Color> _colorsFor(String setting, DistrictTheme district) {
  switch (setting) {
    case 'kitchen':
      return const [Color(0xFF3B2112), Color(0xFF6E3D21), Color(0xFF201009)];
    case 'coffee_shop':
      return const [Color(0xFF302018), Color(0xFF6A4931), Color(0xFF17100C)];
    case 'party':
      return const [Color(0xFF251642), Color(0xFF8F4565), Color(0xFF161020)];
    case 'street':
      return const [Color(0xFF111827), Color(0xFF344155), Color(0xFF070A10)];
    case 'flat':
      return const [Color(0xFF211832), Color(0xFF51415E), Color(0xFF120E18)];
    case 'phone':
      return const [Color(0xFF101014), Color(0xFF25324A), Color(0xFF08090D)];
    case 'desk':
      return const [Color(0xFF101820), Color(0xFF2F455F), Color(0xFF080C11)];
    case 'meeting_room':
      return const [Color(0xFF151A20), Color(0xFF4D5B68), Color(0xFF090C10)];
    case 'review_room':
      return const [Color(0xFF11151A), Color(0xFF657080), Color(0xFF080A0D)];
    case 'office':
      return const [Color(0xFF10141B), Color(0xFF3A4656), Color(0xFF080A0E)];
    default:
      return [
        Color.lerp(Colors.black, district.accent, 0.18)!,
        Color.lerp(Colors.black, district.accent, 0.38)!,
        Colors.black,
      ];
  }
}

/// The setting "plate" — a gradient band carrying the room's identity via
/// colour and a single oversized background glyph, plus a mood-tinted
/// badge. Deliberately wordless: everything it communicates it
/// communicates without text.
///
/// [district] is currently unused for rendering but kept on the
/// constructor so callers ([SceneCard], [SceneModal]) don't need touching
/// when the accent is wanted again.
class SceneSettingPlate extends StatelessWidget {
  final SceneVisualStyle visual;
  final MoodStyle mood;
  final DistrictTheme district;
  final bool compact;

  const SceneSettingPlate({
    super.key,
    required this.visual,
    required this.mood,
    required this.district,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 14 : 22);

    return Container(
      height: compact ? 72 : 104,
      // Clips the oversized background glyph to the plate's own corners.
      // Without this the icon overflows the right edge of the card.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: visual.colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -22,
            child: Icon(
              visual.icon,
              size: compact ? 88 : 132,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Container(
              width: compact ? 34 : 42,
              height: compact ? 34 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood.primary.withValues(alpha: 0.18),
                border: Border.all(color: mood.primary.withValues(alpha: 0.4)),
              ),
              child: Icon(
                visual.icon,
                size: compact ? 17 : 21,
                color: mood.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single authored line naming the invisible tension of the beat.
///
/// Renders only when a node actually authors `visual.pressure`. It must
/// never fall back to joining [SceneVisualStyle.props] — that produced
/// machine-generated copy like "CURSOR / TIMESTAMP / UPLOAD" on every
/// undecorated scene node.
class ScenePressureLine extends StatelessWidget {
  final SceneVisualStyle visual;
  final Color accent;

  const ScenePressureLine({
    super.key,
    required this.visual,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (visual.pressure.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.circle, size: 7, color: accent.withValues(alpha: 0.72)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            visual.pressure.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}