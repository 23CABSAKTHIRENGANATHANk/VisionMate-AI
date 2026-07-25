import 'dart:math';

import 'package:flutter/material.dart';

import '../../../services/navigation_pipeline_processor.dart';
import '../../../services/obstacle_priority_analyzer.dart';
import '../../detection/detection_result.dart';

/// Paints detected object bounding boxes, priority color coding, distance estimations,
/// and labels on top of the camera view.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.detections,
    this.processor,
  });

  final List<DetectionResult> detections;
  final NavigationPipelineProcessor? processor;

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    final pipelineProcessor = processor ?? NavigationPipelineProcessor.instance;
    final navData = pipelineProcessor.process(detections);

    return IgnorePointer(
      child: CustomPaint(
        painter: _DetectionPainter(obstacles: navData.obstacles),
        size: Size.infinite,
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter({required this.obstacles});

  final List<ProcessedObstacle> obstacles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final obstacle in obstacles) {
      final detection = obstacle.detection;
      final color = obstacle.tierColor;

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = obstacle.priorityTier == ObstaclePriorityTier.critical ? 4.0 : 3.0
        ..color = color;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color.fromRGBO(0, 0, 0, 0.70);

      final rect = Rect.fromLTRB(
        detection.rect.left * size.width,
        detection.rect.top * size.height,
        detection.rect.right * size.width,
        detection.rect.bottom * size.height,
      ).deflate(2);

      // Draw bounding box rect
      canvas.drawRect(rect, boxPaint);

      // Label text with distance & confidence
      final textSpan = TextSpan(
        text:
            '${detection.label} • ${obstacle.distance.formattedDistance} (${(detection.confidence * 100).toStringAsFixed(0)}%)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: max(100.0, size.width - 32));

      final labelRect = Rect.fromLTWH(
        rect.left,
        max(0.0, rect.top - tp.height - 8),
        tp.width + 14,
        tp.height + 8,
      );

      // Draw label background pill with priority border indicator
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        fillPaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        borderPaint,
      );

      tp.paint(canvas, Offset(labelRect.left + 7, labelRect.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.obstacles != obstacles;
  }
}
