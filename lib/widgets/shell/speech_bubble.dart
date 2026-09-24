import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A spoken line, drawn by the app at the speaker's mouth.
///
/// Native rather than baked into the artwork, because a balloon composed into
/// the frame is anchored to canvas coordinates the shell's camera crops away,
/// and because text drawn here reflows, scales with the OS text size and stays
/// legible at a phone's pixel density.
///
/// Laid out arithmetically rather than by trial: the text is measured with a
/// TextPainter so the bubble's height is known before it is positioned, which
/// is what lets the tail sit ON the mouth and the top still be clamped clear of
/// the status bar. A bubble that had to be laid out first and moved afterwards
/// would land in the notch for one frame every time.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.mouth,
    required this.viewportWidth,
    required this.topLimit,
    required this.bottomLimit,
  });

  final String text;

  /// The mouth in stage coordinates — already projected from the canvas by
  /// ShellCamera.project, so this widget does no camera maths of its own.
  final Offset mouth;

  final double viewportWidth;

  /// The lowest the bubble's top may go — the status inset plus its margin.
  final double topLimit;

  /// The highest the bubble's bottom may go — the top of the narration panel.
  final double bottomLimit;

  static const double _tailWidth = 12;
  static const double _tailHeight = 15;
  static const double _radius = 14;
  static const double _padH = 14;
  static const double _padV = 11;
  static const double _gap = 6;
  static const double _maxContent = 230;

  @override
  Widget build(BuildContext context) {
    // room on each side of the mouth, less the margin the bubble keeps from the
    // screen edge; speak into whichever side has more of it
    const edge = 12.0;
    final roomRight = viewportWidth - mouth.dx - _gap - edge;
    final roomLeft = mouth.dx - _gap - edge;
    final toRight = roomRight >= roomLeft;
    final room = toRight ? roomRight : roomLeft;

    final contentWidth =
        math.min(_maxContent, room - _padH * 2 - _tailWidth).floorToDouble();
    // nowhere to put it: a bubble narrower than this is unreadable, and the
    // line is still in the payload for whoever wants to log it
    if (contentWidth < 90) return const SizedBox.shrink();

    final style = TextStyle(
      fontSize: 15,
      height: 1.32,
      color: Colors.white.withValues(alpha: 0.97),
    );

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 6,
    )..layout(maxWidth: contentWidth);

    final bubbleWidth = painter.width + _padH * 2 + _tailWidth;
    final bubbleHeight = painter.height + _padV * 2;

    // centred on the mouth, then pushed clear of the status bar and the panel
    var top = mouth.dy - bubbleHeight / 2;
    final lowestTop = bottomLimit - bubbleHeight - 8;
    top = top.clamp(topLimit, math.max(topLimit, lowestTop));

    final left = toRight
        ? mouth.dx + _gap
        : mouth.dx - _gap - bubbleWidth;

    // where the tail meets the body, in the bubble's own coordinates, kept a
    // corner's width away from either end so it never grows out of the radius
    final tailY = (mouth.dy - top).clamp(_radius + 4, bubbleHeight - _radius - 4);

    return Positioned(
      left: left,
      top: top,
      width: bubbleWidth,
      height: bubbleHeight,
      child: TweenAnimationBuilder<double>(
        // fades in on its own, because the shell holds it back behind a
        // character introduction and it must not simply appear the instant
        // the lower-third clears
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: CustomPaint(
          painter: _BubblePainter(toRight: toRight, tailY: tailY),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              toRight ? _tailWidth + _padH : _padH,
              _padV,
              toRight ? _padH : _tailWidth + _padH,
              _padV,
            ),
            child: Text(text, style: style, maxLines: 6),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.toRight, required this.tailY});

  /// True when the bubble sits to the RIGHT of the mouth, which puts its tail
  /// on its own left edge.
  final bool toRight;
  final double tailY;

  @override
  void paint(Canvas canvas, Size size) {
    const r = SpeechBubble._radius;
    const tw = SpeechBubble._tailWidth;

    final body = toRight
        ? Rect.fromLTWH(tw, 0, size.width - tw, size.height)
        : Rect.fromLTWH(0, 0, size.width - tw, size.height);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(r)));

    // one path, so the fill has no seam where the tail meets the body and the
    // outline runs round the whole shape in a single stroke
    final tail = Path();
    if (toRight) {
      tail
        ..moveTo(tw, tailY - 9)
        ..lineTo(0, tailY)
        ..lineTo(tw, tailY + 9)
        ..close();
    } else {
      tail
        ..moveTo(size.width - tw, tailY - 9)
        ..lineTo(size.width, tailY)
        ..lineTo(size.width - tw, tailY + 9)
        ..close();
    }

    final shape = Path.combine(PathOperation.union, path, tail);

    canvas.drawPath(
      shape,
      Paint()..color = const Color(0xFF14181E).withValues(alpha: 0.88),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.toRight != toRight || old.tailY != tailY;
}