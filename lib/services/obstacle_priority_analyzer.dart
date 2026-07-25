import 'package:flutter/material.dart';

import '../features/detection/detection_result.dart';
import 'distance_estimator.dart';
import 'position_analyzer.dart';

/// Priority tiers for obstacle warning urgency.
enum ObstaclePriorityTier {
  /// Immediate high-danger hazard directly in navigation path.
  critical,

  /// High priority obstacle requiring attention.
  high,

  /// Medium priority obstacle in environmental vicinity.
  medium,

  /// Low priority or distant object.
  low,
}

/// Rich obstacle metadata bundle evaluated through position and distance estimators.
class ProcessedObstacle {
  const ProcessedObstacle({
    required this.detection,
    required this.position,
    required this.distance,
    required this.priorityScore,
    required this.priorityTier,
  });

  final DetectionResult detection;
  final SpatialPosition position;
  final DistanceData distance;
  final double priorityScore;
  final ObstaclePriorityTier priorityTier;

  String get label => detection.label;

  /// Summary description (e.g. "Chair • 1.2m directly ahead").
  String get summary =>
      '${detection.label} • ${distance.formattedDistance} ${position.readableDirection}';

  /// Priority color for visual UI overlays.
  Color get tierColor {
    switch (priorityTier) {
      case ObstaclePriorityTier.critical:
        return const Color(0xFFFF3B30); // Vibrant Red
      case ObstaclePriorityTier.high:
        return const Color(0xFFFF9500); // Orange
      case ObstaclePriorityTier.medium:
        return const Color(0xFFFFCC00); // Yellow
      case ObstaclePriorityTier.low:
        return const Color(0xFF34C759); // Green
    }
  }
}

/// Evaluates and ranks detected obstacles based on proximity, alignment, and hazard tier.
class ObstaclePriorityAnalyzer {
  const ObstaclePriorityAnalyzer();

  /// Critical hazard classes that present immediate physical navigation danger.
  static const Set<String> _highDangerClasses = {
    'stairs',
    'step',
    'car',
    'truck',
    'bus',
    'hole',
    'door',
    'traffic light',
  };

  /// Moderate hazard classes that are physical obstacles.
  static const Set<String> _moderateDangerClasses = {
    'person',
    'dog',
    'bicycle',
    'motorcycle',
    'chair',
    'couch',
    'sofa',
    'table',
    'dining table',
  };

  /// Evaluates raw detection with spatial position & distance to produce a prioritized obstacle.
  ProcessedObstacle evaluate({
    required DetectionResult detection,
    required SpatialPosition position,
    required DistanceData distance,
  }) {
    double score = 0.0;

    // 1. Proximity Score (up to 50 points)
    switch (distance.category) {
      case ProximityCategory.immediate:
        score += 50.0;
        break;
      case ProximityCategory.near:
        score += 35.0;
        break;
      case ProximityCategory.medium:
        score += 20.0;
        break;
      case ProximityCategory.far:
        score += 5.0;
        break;
    }

    // 2. Direct Path Collision Score (up to 30 points)
    if (position.horizontalZone == HorizontalZone.center) {
      score += 30.0;
    } else {
      score += 10.0;
    }

    // 3. Object Hazard Class Score (up to 20 points)
    final labelLower = detection.label.toLowerCase().trim();
    if (_highDangerClasses.contains(labelLower)) {
      score += 20.0;
    } else if (_moderateDangerClasses.contains(labelLower)) {
      score += 15.0;
    } else {
      score += 5.0;
    }

    // Scale by model confidence score
    score *= detection.confidence.clamp(0.5, 1.0);

    // Determine priority tier
    final ObstaclePriorityTier tier;
    if (score >= 68.0) {
      tier = ObstaclePriorityTier.critical;
    } else if (score >= 48.0) {
      tier = ObstaclePriorityTier.high;
    } else if (score >= 28.0) {
      tier = ObstaclePriorityTier.medium;
    } else {
      tier = ObstaclePriorityTier.low;
    }

    return ProcessedObstacle(
      detection: detection,
      position: position,
      distance: distance,
      priorityScore: score,
      priorityTier: tier,
    );
  }
}
