import 'package:flutter/material.dart';

/// Position of the obstacle relative to the user's field of view.
enum ObjectHorizontalPosition {
  left,
  center,
  right,
}

/// Priority tier based on proximity and collision risk.
enum ObjectPriorityTier {
  critical, // < 1.2m directly in walking path
  warning,  // 1.2m - 2.5m in walking path or close side hazard
  info,     // > 2.5m or ambient background object
}

/// Represents a dynamically tracked object across video frames with smoothed
/// bounding box coordinates and Kalman/EMA distance estimation.
class TrackedObject {
  TrackedObject({
    required this.trackingId,
    required this.label,
    required this.confidence,
    required this.rawRect,
    required this.smoothedRect,
    required this.distanceMeters,
    required this.smoothedDistanceMeters,
    required this.position,
    required this.priorityTier,
    required this.lastSeen,
  });

  final int trackingId;
  final String label;
  final double confidence;
  final Rect rawRect;
  final Rect smoothedRect;
  final double distanceMeters;
  final double smoothedDistanceMeters;
  final ObjectHorizontalPosition position;
  final ObjectPriorityTier priorityTier;
  final DateTime lastSeen;

  /// Formatted direction string for speech synthesizer.
  String get directionalSpeechText {
    final distStr = smoothedDistanceMeters < 1.0
        ? '${(smoothedDistanceMeters * 100).round()} centimeters'
        : '${smoothedDistanceMeters.toStringAsFixed(1)} meters';

    switch (position) {
      case ObjectHorizontalPosition.center:
        return '$label ahead $distStr.';
      case ObjectHorizontalPosition.left:
        return '$label on your left $distStr.';
      case ObjectHorizontalPosition.right:
        return '$label on your right $distStr.';
    }
  }

  TrackedObject copyWith({
    int? trackingId,
    String? label,
    double? confidence,
    Rect? rawRect,
    Rect? smoothedRect,
    double? distanceMeters,
    double? smoothedDistanceMeters,
    ObjectHorizontalPosition? position,
    ObjectPriorityTier? priorityTier,
    DateTime? lastSeen,
  }) {
    return TrackedObject(
      trackingId: trackingId ?? this.trackingId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      rawRect: rawRect ?? this.rawRect,
      smoothedRect: smoothedRect ?? this.smoothedRect,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      smoothedDistanceMeters:
          smoothedDistanceMeters ?? this.smoothedDistanceMeters,
      position: position ?? this.position,
      priorityTier: priorityTier ?? this.priorityTier,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
