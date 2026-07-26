import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../../../models/tracked_object.dart';
import '../../../services/obstacle_priority_analyzer.dart';
import '../../detection/bounding_box_painter.dart';
import '../../detection/detection_result.dart';

/// Overlay widget rendering smooth, anti-flicker object tracking bounding boxes,
/// label names, confidence percentages, and dynamic pinhole distance estimations.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    this.trackedObjects = const <TrackedObject>[],
    this.mlKitObjects = const <DetectedObject>[],
    this.imageSize = Size.zero,
    this.rotation = InputImageRotation.rotation0deg,
    this.obstacles = const <ProcessedObstacle>[],
    this.detections = const <DetectionResult>[],
  });

  /// Smoothly tracked objects from VisionNavigationEngine.
  final List<TrackedObject> trackedObjects;

  /// Google ML Kit detected objects.
  final List<DetectedObject> mlKitObjects;
  final Size imageSize;
  final InputImageRotation rotation;

  /// Pre-processed obstacles.
  final List<ProcessedObstacle> obstacles;

  /// Raw detections.
  final List<DetectionResult> detections;

  @override
  Widget build(BuildContext context) {
    if (trackedObjects.isNotEmpty || detections.isNotEmpty || mlKitObjects.isNotEmpty) {
      return IgnorePointer(
        child: CustomPaint(
          painter: BoundingBoxPainter(
            trackedObjects: trackedObjects,
            detections: detections,
            mlKitObjects: mlKitObjects,
            imageSize: imageSize,
            rotation: rotation,
          ),
          size: Size.infinite,
        ),
      );
    }

    if (obstacles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: BoundingBoxPainter(
          detections: detections,
        ),
        size: Size.infinite,
      ),
    );
  }
}
