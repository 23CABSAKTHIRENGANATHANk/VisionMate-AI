import 'package:flutter/material.dart';

/// Immutable detection result for a single object from the AI model.
class DetectionResult {
  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.rect,
  });

  /// The detected object label.
  final String label;

  /// The detection confidence score (0.0 to 1.0).
  final double confidence;

  /// The bounding box in normalized coordinates [0.0, 1.0].
  final Rect rect;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionResult &&
        other.label == label &&
        other.confidence == confidence &&
        other.rect == rect;
  }

  @override
  int get hashCode => Object.hash(label, confidence, rect);
}
