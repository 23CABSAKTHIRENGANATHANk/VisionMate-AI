import 'package:flutter/material.dart';

import '../../detection/detection_result.dart';
import 'spatial_enums.dart';

/// Module 6 — Primary Navigation Object model representing spatial understanding
/// for detected entities in the environment.
class NavigationObject {
  const NavigationObject({
    required this.label,
    required this.confidence,
    required this.direction,
    required this.distance,
    required this.risk,
    required this.rect,
  });

  /// The detected object class label.
  final String label;

  /// The model detection confidence score [0.0 - 1.0].
  final double confidence;

  /// Spatial direction relative to camera field of view (left, center, right).
  final ObjectDirection direction;

  /// Estimated proximity tier (near, medium, far).
  final ObjectDistance distance;

  /// Evaluated hazard risk level (low, medium, high, critical).
  final RiskLevel risk;

  /// The normalized bounding box coordinates [0.0 - 1.0].
  final Rect rect;

  /// Factory constructor converting raw [DetectionResult] with spatial calculations.
  factory NavigationObject.fromDetection({
    required DetectionResult detection,
    required ObjectDirection direction,
    required ObjectDistance distance,
    required RiskLevel risk,
  }) {
    return NavigationObject(
      label: detection.label,
      confidence: detection.confidence,
      direction: direction,
      distance: distance,
      risk: risk,
      rect: detection.rect,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationObject &&
        other.label == label &&
        other.confidence == confidence &&
        other.direction == direction &&
        other.distance == distance &&
        other.risk == risk &&
        other.rect == rect;
  }

  @override
  int get hashCode =>
      Object.hash(label, confidence, direction, distance, risk, rect);
}
