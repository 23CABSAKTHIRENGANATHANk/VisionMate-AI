import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../../models/tracked_object.dart';
import 'detection_result.dart';

/// BoundingBoxPainter paints smooth, anti-flicker bounding boxes with priority
/// color coding, category labels, confidence %, and pinhole distance metrics.
class BoundingBoxPainter extends CustomPainter {
  BoundingBoxPainter({
    this.trackedObjects = const <TrackedObject>[],
    this.detections = const <DetectionResult>[],
    this.mlKitObjects = const <DetectedObject>[],
    this.imageSize = Size.zero,
    this.rotation = InputImageRotation.rotation0deg,
  });

  final List<TrackedObject> trackedObjects;
  final List<DetectionResult> detections;
  final List<DetectedObject> mlKitObjects;
  final Size imageSize;
  final InputImageRotation rotation;

  static const List<Color> _palette = [
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFF007AFF), // Blue
    Color(0xFFFF3B30), // Red
    Color(0xFF5856D6), // Purple
    Color(0xFFFFCC00), // Yellow
    Color(0xFF30B0C7), // Teal
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (trackedObjects.isNotEmpty) {
      _paintTrackedObjects(canvas, size);
      return;
    }

    if (detections.isNotEmpty) {
      _paintDetectionResults(canvas, size);
      return;
    }

    if (mlKitObjects.isNotEmpty && imageSize.width > 0 && imageSize.height > 0) {
      _paintMlKitObjects(canvas, size);
    }
  }

  void _paintTrackedObjects(Canvas canvas, Size size) {
    for (final obj in trackedObjects) {
      final Color tierColor;
      switch (obj.priorityTier) {
        case ObjectPriorityTier.critical:
          tierColor = const Color(0xFFFF3B30); // Red
          break;
        case ObjectPriorityTier.warning:
          tierColor = const Color(0xFFFF9500); // Orange
          break;
        case ObjectPriorityTier.info:
          tierColor = _palette[obj.trackingId.abs() % _palette.length];
          break;
      }

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = obj.priorityTier == ObjectPriorityTier.critical ? 4.0 : 3.0
        ..color = tierColor;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 0, 0.75);

      final rect = Rect.fromLTRB(
        obj.smoothedRect.left * size.width,
        obj.smoothedRect.top * size.height,
        obj.smoothedRect.right * size.width,
        obj.smoothedRect.bottom * size.height,
      );

      // Draw smooth bounding box with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        boxPaint,
      );

      // Distance formatting
      final String formattedDist = obj.smoothedDistanceMeters < 1.0
          ? '${(obj.smoothedDistanceMeters * 100).round()}cm'
          : '${obj.smoothedDistanceMeters.toStringAsFixed(1)}m';

      final String text =
          '${obj.label} • $formattedDist (${(obj.confidence * 100).toStringAsFixed(0)}%)';

      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: max(100.0, size.width - 32));

      final labelRect = Rect.fromLTWH(
        rect.left,
        max(0.0, rect.top - textPainter.height - 8),
        textPainter.width + 14,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        fillPaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = tierColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        borderPaint,
      );

      textPainter.paint(
        canvas,
        Offset(labelRect.left + 7, labelRect.top + 3),
      );
    }
  }

  void _paintDetectionResults(Canvas canvas, Size size) {
    for (var i = 0; i < detections.length; i++) {
      final item = detections[i];
      final color = _palette[i % _palette.length];

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = color;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 0, 0.75);

      final rect = Rect.fromLTRB(
        item.rect.left * size.width,
        item.rect.top * size.height,
        item.rect.right * size.width,
        item.rect.bottom * size.height,
      );

      canvas.drawRect(rect, boxPaint);

      final String text = '${item.label} (${(item.confidence * 100).toStringAsFixed(0)}%)';
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: max(100.0, size.width - 32));

      final labelRect = Rect.fromLTWH(
        rect.left,
        max(0.0, rect.top - textPainter.height - 8),
        textPainter.width + 14,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        fillPaint,
      );

      textPainter.paint(
        canvas,
        Offset(labelRect.left + 7, labelRect.top + 3),
      );
    }
  }

  void _paintMlKitObjects(Canvas canvas, Size size) {
    final bool isPortrait = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double cameraW = isPortrait ? imageSize.height : imageSize.width;
    final double cameraH = isPortrait ? imageSize.width : imageSize.height;

    final double scaleX = size.width / cameraW;
    final double scaleY = size.height / cameraH;

    for (final obj in mlKitObjects) {
      final trackingId = obj.trackingId ?? 0;
      final color = _palette[trackingId % _palette.length];

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = color;

      final Rect rawBox = obj.boundingBox;
      final Rect scaledRect = Rect.fromLTRB(
        rawBox.left * scaleX,
        rawBox.top * scaleY,
        rawBox.right * scaleX,
        rawBox.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, boxPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.trackedObjects != trackedObjects ||
        oldDelegate.detections != detections ||
        oldDelegate.mlKitObjects != mlKitObjects;
  }
}
