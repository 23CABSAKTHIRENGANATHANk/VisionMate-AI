import 'package:flutter/material.dart';

/// Distance tier categories for navigation decision making.
enum ProximityCategory {
  /// Object is within immediate touch/collision range (< 1.0 meter).
  immediate,

  /// Object is near (1.0 - 3.0 meters).
  near,

  /// Object is at medium range (3.0 - 5.0 meters).
  medium,

  /// Object is far (> 5.0 meters).
  far,
}

/// Estimated distance metrics for a detected object.
class DistanceData {
  const DistanceData({
    required this.distanceMeters,
    required this.category,
    required this.formattedDistance,
  });

  /// Estimated distance in meters.
  final double distanceMeters;

  /// Categorized proximity tier.
  final ProximityCategory category;

  /// Human-readable distance representation (e.g. "1.2m").
  final String formattedDistance;

  /// Spoken text description (e.g., "1.2 meters").
  String get spokenDistance {
    if (distanceMeters < 1.0) {
      final cm = (distanceMeters * 100).round();
      return '$cm centimeters';
    }
    return '${distanceMeters.toStringAsFixed(1)} meters';
  }
}

/// Estimates physical distance of objects from normalized bounding box dimensions.
///
/// ## Calibration note
/// The bounding-box height thresholds (nearHeightThreshold = 0.45,
/// mediumHeightThreshold = 0.20) are kept consistent with the spatial
/// module's [features/spatial/analyzers/distance_estimator.dart] so that
/// both pipeline branches (NavigationPipelineProcessor and SpatialProcessor)
/// agree on near / medium / far classification for the same detection.
class DistanceEstimator {
  const DistanceEstimator({
    this.nearHeightThreshold = 0.45,
    this.mediumHeightThreshold = 0.20,
  });

  /// Box height fraction above which the object is classified as near/immediate.
  /// Aligned with features/spatial/analyzers/distance_estimator.dart nearHeightThreshold.
  final double nearHeightThreshold;

  /// Box height fraction above which the object is classified as medium distance.
  final double mediumHeightThreshold;

  /// Approximate physical heights (in meters) for standard detected object classes.
  static const Map<String, double> _objectReferenceHeights = {
    'person': 1.70,
    'car': 1.50,
    'truck': 2.20,
    'bus': 3.00,
    'bicycle': 1.00,
    'motorcycle': 1.10,
    'chair': 0.90,
    'couch': 0.85,
    'sofa': 0.85,
    'table': 0.75,
    'dining table': 0.75,
    'door': 2.00,
    'stairs': 1.60,
    'step': 0.20,
    'dog': 0.55,
    'cat': 0.30,
    'bottle': 0.25,
    'cup': 0.15,
    'laptop': 0.30,
    'tv': 0.60,
    'plant': 0.60,
    'potted plant': 0.60,
  };

  /// Default focal-length scaling constant calibrated for modern smartphone
  /// vertical FOV (~60°).
  static const double _focalScaleFactor = 0.85;

  /// Estimates the distance in meters given an object label and normalized
  /// bounding box.
  ///
  /// The result uses a two-step approach:
  /// 1. Pinhole camera approximation from real object height and focal scale.
  /// 2. Bounding-box height override: if the box height exceeds the near
  ///    threshold the category is forced to [ProximityCategory.immediate]
  ///    regardless of the formula result — keeping parity with the spatial
  ///    analyzer's threshold-based classification.
  DistanceData estimate(String label, Rect normalizedRect) {
    final lowerLabel = label.toLowerCase().trim();
    final realHeight = _objectReferenceHeights[lowerLabel] ?? 1.0;

    // Use normalized box height (clamp to avoid division by zero)
    final boxHeightNormalized = normalizedRect.height.clamp(0.02, 1.0);

    // Pinhole camera equation approximation:
    //   D = (RealHeight * FocalScale) / NormalizedBoxHeight
    double distanceMeters =
        (realHeight * _focalScaleFactor) / boxHeightNormalized;

    // Clamp distance between 0.3 m and 15.0 m for safety boundaries.
    distanceMeters = distanceMeters.clamp(0.3, 15.0);

    // ── Determine proximity category ─────────────────────────────────────────
    //
    // Box-height override ensures consistency with the spatial analyzer:
    // if the bounding box fills ≥ 45 % of the frame height the object is
    // by definition very close — classify as immediate.
    final ProximityCategory category;
    if (normalizedRect.height >= nearHeightThreshold ||
        distanceMeters < 1.0) {
      category = ProximityCategory.immediate;
    } else if (normalizedRect.height >= mediumHeightThreshold ||
        distanceMeters < 3.0) {
      category = ProximityCategory.near;
    } else if (distanceMeters < 5.0) {
      category = ProximityCategory.medium;
    } else {
      category = ProximityCategory.far;
    }

    final String formatted = distanceMeters < 1.0
        ? '${(distanceMeters * 100).round()}cm'
        : '${distanceMeters.toStringAsFixed(1)}m';

    return DistanceData(
      distanceMeters: distanceMeters,
      category: category,
      formattedDistance: formatted,
    );
  }
}
