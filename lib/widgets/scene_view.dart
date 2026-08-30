import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The composed scene for a node: 16:9 artwork, contained, never cropped.
///
/// Under the locked 2B layout the artwork is the whole picture — dialogue
/// balloons are drawn inside the SVG by the server, with tails pointing at the
/// speaker. This widget therefore draws exactly one thing and draws it whole.
/// Choices live below it, owned by the screen, never overlaid.
///
/// Cropping is not an option. The 4:5 safe area in anchors.json is a
/// composition constraint the artwork was authored against, not a crop rule:
/// prop placement, bubble origins and the occlusion line were all solved for
/// the full 1600×900 frame. Cropping would reintroduce, on the client, the
/// exact class of defect the 2B.6 gate was built to catch.
class SceneView extends StatelessWidget {
  const SceneView({
    super.key,
    required this.svg,
    this.cacheKey,
    this.headAnchors,
    this.background = const Color(0xFF141416),
    this.semanticLabel,
  });

  /// The composed SVG string from `node.render.svg`. Null for nodes with no
  /// artwork — `messages` mode, and any node the visual contract declined to
  /// compose. Both are normal states, not errors.
  final String? svg;

  /// `node.render.cacheKey`. Used only as a widget key so Flutter rebuilds the
  /// picture when the visual state genuinely changes and reuses it when the
  /// same visual recurs — the same identity the server caches on.
  final String? cacheKey;

  /// `node.render.headAnchors`: resolved head positions in viewBox coordinates.
  /// Unused today because bubbles are inside the SVG. Kept on the widget so
  /// native dialogue, if it ever happens, needs no server change.
  final Map<String, dynamic>? headAnchors;

  final Color background;
  final String? semanticLabel;

  static const double aspect = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final source = svg;
    if (source == null || source.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: aspect,
      child: ColoredBox(
        color: background,
        child: SvgPicture.string(
          source,
          key: cacheKey == null ? null : ValueKey<String>(cacheKey!),
          // contain, not cover: cover would crop the authored composition
          fit: BoxFit.contain,
          alignment: Alignment.center,
          semanticsLabel: semanticLabel,
          placeholderBuilder: (_) => const _SceneLoading(),
        ),
      ),
    );
  }
}

class _SceneLoading extends StatelessWidget {
  const _SceneLoading();

  @override
  Widget build(BuildContext context) {
    // Deliberately inert. A spinner over a frame that parses in a few
    // milliseconds reads as jank; an empty frame of the right shape does not
    // move the layout when the artwork lands.
    return const SizedBox.expand();
  }
}

/// Artwork above, prose and choices below — the locked phone layout.
///
/// Kept separate from [SceneView] so the widget that draws the picture has no
/// opinion about what sits under it.
class SceneLayout extends StatelessWidget {
  const SceneLayout({
    super.key,
    required this.scene,
    required this.body,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28),
  });

  final Widget scene;
  final Widget body;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        scene,
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: body,
          ),
        ),
      ],
    );
  }
}