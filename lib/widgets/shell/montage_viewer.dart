import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/scene_render.dart';
import 'scene_stage.dart';

/// A montage, one panel at a time.
///
/// The server composes three reduced-fidelity vignettes side by side on the
/// same 1600x900 canvas, which is right for a 16:9 surface and wrong for a
/// phone: the shell's camera would show the middle panel and crop the other two
/// off the sides. Each vignette is natively 4:5 though, so a window on ONE
/// panel crops nothing at all — which is why the renderer now reports where the
/// panels are instead of the client guessing at three x values.
///
/// Swiped rather than timed. Compressed time is the point of a montage, and a
/// player who wants to sit on the middle panel should be able to.
class MontageViewer extends StatefulWidget {
  const MontageViewer({
    super.key,
    required this.svg,
    required this.panels,
    required this.accent,
    this.cacheKey,
    this.obscuredBottom = 0,
    this.background = const Color(0xFF0B0E13),
  });

  final String svg;
  final List<MontagePanel> panels;
  final Color accent;
  final String? cacheKey;

  /// How much of the bottom of this box the narration panel covers. The panel
  /// always overlaps the artwork by at least 24 so the two never part, which
  /// would put the pager dots and the caption underneath it.
  final double obscuredBottom;

  final Color background;

  @override
  State<MontageViewer> createState() => _MontageViewerState();
}

class _MontageViewerState extends State<MontageViewer> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // the montage occupies exactly the box an ordinary scene would, so the
        // panel below it does not move between a scene node and a montage node
        final height = ShellCamera.artHeight(width);

        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: widget.background,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: widget.panels.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _Panel(
                    svg: widget.svg,
                    cacheKey: widget.cacheKey,
                    panel: widget.panels[i],
                    index: i,
                    obscuredBottom: widget.obscuredBottom + 22,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: widget.obscuredBottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.panels.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? widget.accent
                                : Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One panel of the composed montage, windowed out of the shared canvas.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.svg,
    required this.panel,
    required this.index,
    required this.obscuredBottom,
    this.cacheKey,
  });

  final String svg;
  final MontagePanel panel;
  final int index;
  final double obscuredBottom;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final caption = panel.caption?.trim() ?? '';
        // room for the caption drawn natively below the panel — the one baked
        // into the SVG sits outside the panel rectangle and would be cropped
        final captionSpace = caption.isEmpty ? 0.0 : 34.0;
        final available = Size(
          box.width - 24,
          box.height - 20 - captionSpace - obscuredBottom,
        );

        // contain: a vignette is 4:5 and the box is not, so fit the whole panel
        // rather than filling — this is the one place in the shell that must
        // not crop, because a montage panel IS the composition
        final scale = math.max(
          0.0,
          math.min(
            available.width / panel.width,
            available.height / panel.height,
          ),
        );
        final w = panel.width * scale;
        final h = panel.height * scale;

        return Padding(
          padding: EdgeInsets.only(bottom: obscuredBottom),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: w,
              height: h,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -panel.x * scale,
                      top: -panel.y * scale,
                      width: ShellCamera.canvasWidth * scale,
                      height: ShellCamera.canvasHeight * scale,
                      child: SvgPicture.string(
                        svg,
                        key: cacheKey == null
                            ? null
                            : ValueKey<String>('$cacheKey-$index'),
                        width: ShellCamera.canvasWidth * scale,
                        height: ShellCamera.canvasHeight * scale,
                        fit: BoxFit.fill,
                        placeholderBuilder: (_) => const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                caption.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
          ),
        );
      },
    );
  }
}