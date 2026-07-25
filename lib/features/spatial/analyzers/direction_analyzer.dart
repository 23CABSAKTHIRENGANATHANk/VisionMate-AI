import 'package:flutter/material.dart';

import '../models/spatial_enums.dart';

/// Modular analyzer responsible for evaluating object center positions
/// into horizontal directions (left, center, right).
class DirectionAnalyzer {
  const DirectionAnalyzer({
    this.leftThreshold = 0.35,
    this.rightThreshold = 0.65,
  });

  /// Horizontal boundary threshold dividing left and center regions.
  final double leftThreshold;

  /// Horizontal boundary threshold dividing center and right regions.
  final double rightThreshold;

  /// Determines horizontal [ObjectDirection] from normalized bounding box bounds.
  ObjectDirection analyze(Rect rect) {
    final centerX = (rect.left + rect.right) / 2.0;

    if (centerX < leftThreshold) {
      return ObjectDirection.left;
    } else if (centerX > rightThreshold) {
      return ObjectDirection.right;
    } else {
      return ObjectDirection.center;
    }
  }
}
