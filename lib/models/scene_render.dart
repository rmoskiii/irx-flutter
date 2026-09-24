import 'package:flutter/foundation.dart';

/// Presentation data for a node: the composed scene, where the heads and mouths
/// are, what is said, and — for a montage — where its panels sit.
///
/// Deliberately thin. This is a courier for what the server already decided —
/// the client resolves nothing, chooses no variant and reads no state. If a
/// node has no artwork (`messages` mode, or a node the visual contract declined
/// to compose) the whole object is absent, which is a normal state.
@immutable
class SceneRender {
  const SceneRender({
    required this.svg,
    required this.cacheKey,
    this.aspect = '16:9',
    this.canvas = '0 0 1600 900',
    this.headAnchors = const {},
    this.mouthAnchors = const {},
    this.dialogue = const [],
    this.montage,
    this.warnings = const [],
  });

  /// The composed SVG, tokens already flattened server-side because
  /// flutter_svg cannot resolve CSS custom properties.
  final String svg;

  /// SHA-256 of the resolved render block. Two scenario states that resolve to
  /// the same picture share this, so it doubles as a widget key: the frame is
  /// rebuilt when the visual genuinely changes and reused when it doesn't.
  final String cacheKey;

  final String aspect;
  final String canvas;

  /// Resolved head positions in viewBox coordinates, keyed by character id.
  /// The neck join, which is the one point a head tilt leaves fixed — useful
  /// for deciding which side of a figure has room, not for aiming a tail.
  final Map<String, Offset2D> headAnchors;

  /// Resolved mouth positions in viewBox coordinates, keyed by character id.
  /// Where a speech bubble points. Absent for rear registers and for every
  /// figure that predates The Streets, so a consumer must fall back to
  /// [headAnchors] rather than treat a missing mouth as an error.
  final Map<String, Offset2D> mouthAnchors;

  /// What is said on this node, already removed from the prose by the server so
  /// a line is never read twice. Empty for scenarios whose dialogue is baked
  /// into the artwork instead, which is still the default.
  final List<SceneDialogue> dialogue;

  /// Panel rectangles for a montage frame, in viewBox coordinates. Null for
  /// every ordinary scene.
  final MontageGeometry? montage;

  /// Non-fatal notes from the renderer — a prop the scene has no anchor for,
  /// for instance. Worth logging in debug; never shown to a player.
  final List<String> warnings;

  static SceneRender? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final svg = json['svg'] as String?;
    if (svg == null || svg.isEmpty) return null;

    final warnings = <String>[];
    final w = json['warnings'];
    if (w is List) {
      for (final item in w) {
        if (item is Map && item['code'] != null) {
          warnings.add('${item['code']}: ${item['id'] ?? ''}'.trim());
        }
      }
    }

    final lines = <SceneDialogue>[];
    final d = json['dialogue'];
    if (d is List) {
      for (final item in d) {
        if (item is Map) {
          final text = item['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            lines.add(SceneDialogue(
              speaker: item['speaker'] as String?,
              text: text,
            ));
          }
        }
      }
    }

    return SceneRender(
      svg: svg,
      cacheKey: json['cacheKey'] as String? ?? '',
      aspect: json['aspect'] as String? ?? '16:9',
      canvas: json['canvas'] as String? ?? '0 0 1600 900',
      headAnchors: _anchors(json['headAnchors']),
      mouthAnchors: _anchors(json['mouthAnchors']),
      dialogue: lines,
      montage: MontageGeometry.fromJson(json['montage']),
      warnings: warnings,
    );
  }

  static Map<String, Offset2D> _anchors(Object? raw) {
    final out = <String, Offset2D>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          final x = (value['x'] as num?)?.toDouble();
          final y = (value['y'] as num?)?.toDouble();
          if (x != null && y != null) out['$key'] = Offset2D(x, y);
        }
      });
    }
    return out;
  }

  /// Where a bubble for [speaker] should point: the mouth if the contract knows
  /// it, otherwise the head. Null when the speaker isn't in this frame at all —
  /// a remote line, or a figure that has left.
  Offset2D? anchorFor(String? speaker) {
    if (speaker == null) return null;
    return mouthAnchors[speaker] ?? headAnchors[speaker];
  }

  /// Width / height parsed from [aspect], falling back to 16:9 rather than
  /// throwing — a malformed aspect should letterbox, not crash a scenario.
  double get aspectRatio {
    final parts = aspect.split(':');
    if (parts.length != 2) return 16 / 9;
    final w = double.tryParse(parts[0]);
    final h = double.tryParse(parts[1]);
    if (w == null || h == null || h == 0) return 16 / 9;
    return w / h;
  }
}

/// One spoken line. [speaker] is a character id (`char.jay`), matching the keys
/// in [SceneRender.mouthAnchors]; null for a line with no figure on screen.
@immutable
class SceneDialogue {
  const SceneDialogue({required this.text, this.speaker});
  final String text;
  final String? speaker;
}

/// Where a montage's panels are on the canvas, so a phone can show one at a
/// time instead of a 16:9 strip of three.
@immutable
class MontageGeometry {
  const MontageGeometry(this.panels);
  final List<MontagePanel> panels;

  static MontageGeometry? fromJson(Object? json) {
    if (json is! Map) return null;
    final raw = json['panels'];
    if (raw is! List || raw.isEmpty) return null;
    final panels = <MontagePanel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final x = (item['x'] as num?)?.toDouble();
      final y = (item['y'] as num?)?.toDouble();
      final w = (item['width'] as num?)?.toDouble();
      final h = (item['height'] as num?)?.toDouble();
      if (x == null || y == null || w == null || h == null) continue;
      panels.add(MontagePanel(
        x: x,
        y: y,
        width: w,
        height: h,
        caption: item['caption'] as String?,
      ));
    }
    return panels.isEmpty ? null : MontageGeometry(panels);
  }
}

@immutable
class MontagePanel {
  const MontagePanel({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.caption,
  });
  final double x;
  final double y;
  final double width;
  final double height;
  final String? caption;
}

/// A point in the SVG's own viewBox coordinate space (0 0 1600 900), not in
/// logical pixels. Convert against the rendered box before using it for layout.
@immutable
class Offset2D {
  const Offset2D(this.x, this.y);
  final double x;
  final double y;

  @override
  String toString() => 'Offset2D($x, $y)';
}