import 'package:flutter/foundation.dart';

/// Presentation data for a node: the composed scene and where the heads are.
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
  /// Unused while bubbles live inside the SVG; carried so native dialogue,
  /// if it ever happens, needs no server change.
  final Map<String, Offset2D> headAnchors;

  /// Non-fatal notes from the renderer — a prop the scene has no anchor for,
  /// for instance. Worth logging in debug; never shown to a player.
  final List<String> warnings;

  static SceneRender? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final svg = json['svg'] as String?;
    if (svg == null || svg.isEmpty) return null;

    final anchors = <String, Offset2D>{};
    final raw = json['headAnchors'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          final x = (value['x'] as num?)?.toDouble();
          final y = (value['y'] as num?)?.toDouble();
          if (x != null && y != null) anchors['$key'] = Offset2D(x, y);
        }
      });
    }

    final warnings = <String>[];
    final w = json['warnings'];
    if (w is List) {
      for (final item in w) {
        if (item is Map && item['code'] != null) {
          warnings.add('${item['code']}: ${item['id'] ?? ''}'.trim());
        }
      }
    }

    return SceneRender(
      svg: svg,
      cacheKey: json['cacheKey'] as String? ?? '',
      aspect: json['aspect'] as String? ?? '16:9',
      canvas: json['canvas'] as String? ?? '0 0 1600 900',
      headAnchors: anchors,
      warnings: warnings,
    );
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