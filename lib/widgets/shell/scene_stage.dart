import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The camera on the 1600x900 canvas.
///
/// The scene is composed at 16:9 for a surface no phone has. Rather than
/// letterbox it — which spends half a portrait screen on black — the shell
/// shows a fixed-width WINDOW of the canvas, scaled to the viewport width and
/// anchored to the top. Everything outside the window is clipped, and the
/// clipped part is scenery: measurement across all 38 Streets frames with a
/// figure put every figure and every story prop inside the middle 720 units,
/// so an 800-unit window has 40 units of margin on each side of the tightest
/// frame.
///
/// [window] is deliberately a constant rather than a per-node value. A camera
/// that changes between beats is a directing decision, and until the week has
/// been played end to end there is nothing to direct with.
class ShellCamera {
  const ShellCamera._();

  static const double canvasWidth = 1600;
  static const double canvasHeight = 900;

  /// Canvas units visible across the viewport width.
  static const double window = 800;

  /// Viewport pixels per canvas unit.
  static double scaleFor(double viewportWidth) => viewportWidth / window;

  /// How tall the artwork draws at this viewport width.
  static double artHeight(double viewportWidth) =>
      canvasHeight * scaleFor(viewportWidth);

  /// Left edge of the window in canvas units — the window is centred, so the
  /// canvas centre (x 800, where every scene puts its figure) is screen centre.
  static const double originX = (canvasWidth - window) / 2;

  /// A canvas point in viewport coordinates, measured from the top-left of the
  /// stage. Used by anything drawn OVER the scene that has to line up with it —
  /// a speech bubble at a mouth anchor, most of all.
  static Offset project(Offset canvasPoint, double viewportWidth) {
    final s = scaleFor(viewportWidth);
    return Offset((canvasPoint.dx - originX) * s, canvasPoint.dy * s);
  }
}

/// The composed scene, full width, anchored to the top, clipped to the camera
/// window.
///
/// Draws exactly one thing and never moves: the panel expands over it, the
/// choices float above it, and neither changes what the stage shows. A scene
/// that shifted when the panel moved would make the room feel like a backdrop
/// on a trolley.
class SceneStage extends StatelessWidget {
  const SceneStage({
    super.key,
    required this.svg,
    this.cacheKey,
    this.background = const Color(0xFF0B0E13),
    this.semanticLabel,
  });

  /// `node.render.svg`. Null for nodes with no artwork, which is normal.
  final String? svg;

  /// `node.render.cacheKey`, used only as a widget key so the picture is
  /// rebuilt when the visual genuinely changes and reused when it recurs.
  final String? cacheKey;

  final Color background;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final source = svg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = ShellCamera.scaleFor(width);
        final artWidth = ShellCamera.canvasWidth * scale;
        final artHeight = ShellCamera.artHeight(width);
        // the window is centred, so the canvas is pulled left by the part of it
        // that sits outside the window on the near side
        final dx = -ShellCamera.originX * scale;

        return SizedBox(
          width: width,
          height: artHeight,
          child: ColoredBox(
            color: background,
            child: (source == null || source.isEmpty)
                ? const SizedBox.expand()
                : ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: dx,
                          top: 0,
                          width: artWidth,
                          height: artHeight,
                          child: SvgPicture.string(
                            source,
                            key: cacheKey == null
                                ? null
                                : ValueKey<String>(cacheKey!),
                            width: artWidth,
                            height: artHeight,
                            // fill, not contain: the box is already exactly
                            // 16:9, so this scales without distorting and
                            // without re-deriving the fit every frame
                            fit: BoxFit.fill,
                            semanticsLabel: semanticLabel,
                            placeholderBuilder: (_) => const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}