import 'package:flutter/material.dart';

import '../models/spatial_enums.dart';

/// Modular distance estimator analyzing bounding box height and area dimensions
/// to estimate proximity tiers (near, medium, far).
class DistanceEstimator {
  const DistanceEstimator({
    this.nearHeightThreshold = 0.45,
    this.nearAreaThreshold = 0.25,
    this.mediumHeightThreshold = 0.20,
    this.mediumAreaThreshold = 0.08,
  });

  final double nearHeightThreshold;
  final double nearAreaThreshold;
  final double mediumHeightThreshold;
  final double mediumAreaThreshold;

  /// Estimates [ObjectDistance] from normalized bounding box dimensions.
  ObjectDistance estimate(Rect rect) {
    final height = rect.height;
    final area = rect.width * rect.height;

    if (height >= nearHeightThreshold || area >= nearAreaThreshold) {
      return ObjectDistance.near;
    } else if (height >= mediumHeightThreshold || area >= mediumAreaThreshold) {
      return ObjectDistance.medium;
    } else {
      return ObjectDistance.far;
    }
  }
}
