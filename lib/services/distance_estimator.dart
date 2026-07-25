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
class DistanceEstimator {
  const DistanceEstimator();

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

  /// Default focal-length scaling constant calibrated for modern smartphone vertical FOV (~60°).
  static const double _focalScaleFactor = 0.85;

  /// Estimates the distance in meters given a object label and normalized bounding box.
  DistanceData estimate(String label, Rect normalizedRect) {
    final lowerLabel = label.toLowerCase().trim();
    final realHeight = _objectReferenceHeights[lowerLabel] ?? 1.0;

    // Use normalized box height (clamp to avoid division by zero)
    final boxHeightNormalized = normalizedRect.height.clamp(0.02, 1.0);

    // Pinhole camera equation approximation: D = (RealHeight * FocalScale) / NormalizedBoxHeight
    double distanceMeters = (realHeight * _focalScaleFactor) / boxHeightNormalized;

    // Clamp distance between 0.3m and 15.0m for safety boundaries
    distanceMeters = distanceMeters.clamp(0.3, 15.0);

    final ProximityCategory category;
    if (distanceMeters < 1.0) {
      category = ProximityCategory.immediate;
    } else if (distanceMeters < 3.0) {
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
