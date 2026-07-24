// ---------------------------------------------------------------------------
// camera_viewfinder_overlay.dart
// Module 3 — Viewfinder corner-bracket overlay for VisionMate AI camera.
//
// Draws four L-shaped corner brackets on top of the live camera preview
// to give a professional viewfinder feel without obscuring the image.
// The brackets and dimensions are all configurable via constructor params.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Draws a transparent viewfinder overlay with corner brackets.
///
/// Place this in a [Stack] on top of the [CameraPreview] widget:
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: [
///     CameraPreview(controller),
///     const CameraViewfinderOverlay(),
///   ],
/// )
/// ```
class CameraViewfinderOverlay extends StatelessWidget {
  const CameraViewfinderOverlay({
    super.key,
    this.bracketColor = Colors.white,
    this.bracketLength = 28.0,
    this.bracketThickness = 3.5,
    this.viewfinderRatio = 0.70,
  });

  /// Colour of the corner-bracket lines.
  final Color bracketColor;

  /// Length of each leg of the corner bracket, in logical pixels.
  final double bracketLength;

  /// Stroke width of the corner-bracket lines.
  final double bracketThickness;

  /// What fraction of the smaller screen dimension the viewfinder occupies.
  final double viewfinderRatio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The overlay is purely decorative — exclude it from the a11y tree.
      excludeSemantics: true,
      child: CustomPaint(
        painter: _ViewfinderPainter(
          bracketColor: bracketColor,
          bracketLength: bracketLength,
          bracketThickness: bracketThickness,
          viewfinderRatio: viewfinderRatio,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ViewfinderPainter — CustomPainter that draws the corner brackets.
// ---------------------------------------------------------------------------

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({
    required this.bracketColor,
    required this.bracketLength,
    required this.bracketThickness,
    required this.viewfinderRatio,
  });

  final Color bracketColor;
  final double bracketLength;
  final double bracketThickness;
  final double viewfinderRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketThickness
      ..strokeCap = StrokeCap.round;

    // Calculate the viewfinder rectangle centred on the canvas.
    final double vfWidth = size.width * viewfinderRatio;
    final double vfHeight = vfWidth * 1.2; // Slightly taller than wide.

    // Clamp height so it doesn't overflow vertically.
    final double clampedHeight = vfHeight.clamp(0.0, size.height * 0.8);

    final double left = (size.width - vfWidth) / 2;
    final double top = (size.height - clampedHeight) / 2;
    final double right = left + vfWidth;
    final double bottom = top + clampedHeight;

    final double bl = bracketLength;

    // ── Top-left corner ──────────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(left, top + bl)
        ..lineTo(left, top)
        ..lineTo(left + bl, top),
      paint,
    );

    // ── Top-right corner ─────────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(right - bl, top)
        ..lineTo(right, top)
        ..lineTo(right, top + bl),
      paint,
    );

    // ── Bottom-left corner ───────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - bl)
        ..lineTo(left, bottom)
        ..lineTo(left + bl, bottom),
      paint,
    );

    // ── Bottom-right corner ──────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(right - bl, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - bl),
      paint,
    );

    // ── Centre crosshair dot (subtle guide) ──────────────────────────────────
    final dotPaint = Paint()
      ..color = bracketColor.withAlpha(128)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      oldDelegate.bracketColor != bracketColor ||
      oldDelegate.bracketLength != bracketLength ||
      oldDelegate.bracketThickness != bracketThickness ||
      oldDelegate.viewfinderRatio != viewfinderRatio;
}
