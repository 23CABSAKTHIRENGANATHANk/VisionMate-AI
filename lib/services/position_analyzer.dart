import 'package:flutter/material.dart';

/// Horizontal position relative to camera field of view.
enum HorizontalZone { left, center, right }

/// Vertical position relative to camera field of view.
enum VerticalZone { top, center, bottom }

/// Position metrics derived from a normalized bounding box.
class SpatialPosition {
  const SpatialPosition({
    required this.centerX,
    required this.centerY,
    required this.horizontalZone,
    required this.verticalZone,
    required this.clockDirection,
    required this.areaFraction,
    required this.readableDirection,
  });

  /// Normalized X coordinate of the box center [0.0 - 1.0].
  final double centerX;

  /// Normalized Y coordinate of the box center [0.0 - 1.0].
  final double centerY;

  /// Coarse horizontal region.
  final HorizontalZone horizontalZone;

  /// Coarse vertical region.
  final VerticalZone verticalZone;

  /// Clock position (10, 11, 12, 1, 2 o'clock) for accessibility speech.
  final int clockDirection;

  /// Fraction of total screen area occupied by the box [0.0 - 1.0].
  final double areaFraction;

  /// Human-readable directional string (e.g., "directly ahead", "on your left").
  final String readableDirection;

  /// Returns true if the object is in the central navigation path.
  bool get isInDirectPath => horizontalZone == HorizontalZone.center;
}

/// Analyzer for converting bounding boxes into spatial positioning metrics.
class PositionAnalyzer {
  const PositionAnalyzer();

  /// Analyzes a normalized bounding box (0.0 to 1.0 range) into spatial metrics.
  SpatialPosition analyze(Rect rect) {
    final centerX = ((rect.left + rect.right) / 2).clamp(0.0, 1.0);
    final centerY = ((rect.top + rect.bottom) / 2).clamp(0.0, 1.0);
    final areaFraction = (rect.width * rect.height).clamp(0.0, 1.0);

    // Determine horizontal zone
    final HorizontalZone horizontalZone;
    if (centerX < 0.35) {
      horizontalZone = HorizontalZone.left;
    } else if (centerX > 0.65) {
      horizontalZone = HorizontalZone.right;
    } else {
      horizontalZone = HorizontalZone.center;
    }

    // Determine vertical zone
    final VerticalZone verticalZone;
    if (centerY < 0.35) {
      verticalZone = VerticalZone.top;
    } else if (centerY > 0.65) {
      verticalZone = VerticalZone.bottom;
    } else {
      verticalZone = VerticalZone.center;
    }

    // Calculate clock direction (centered around 12 o'clock)
    final int clockDirection;
    if (centerX < 0.20) {
      clockDirection = 9;
    } else if (centerX < 0.35) {
      clockDirection = 10;
    } else if (centerX < 0.45) {
      clockDirection = 11;
    } else if (centerX <= 0.55) {
      clockDirection = 12;
    } else if (centerX <= 0.65) {
      clockDirection = 1;
    } else if (centerX <= 0.80) {
      clockDirection = 2;
    } else {
      clockDirection = 3;
    }

    // Generate human-readable string
    final String readableDirection;
    switch (horizontalZone) {
      case HorizontalZone.center:
        readableDirection = 'directly ahead';
        break;
      case HorizontalZone.left:
        readableDirection = 'on your left';
        break;
      case HorizontalZone.right:
        readableDirection = 'on your right';
        break;
    }

    return SpatialPosition(
      centerX: centerX,
      centerY: centerY,
      horizontalZone: horizontalZone,
      verticalZone: verticalZone,
      clockDirection: clockDirection,
      areaFraction: areaFraction,
      readableDirection: readableDirection,
    );
  }
}
