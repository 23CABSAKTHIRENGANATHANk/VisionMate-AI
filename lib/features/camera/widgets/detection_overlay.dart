import 'dart:math';

import 'package:flutter/material.dart';

import '../../detection/detection_result.dart';

/// Paints detected object bounding boxes and labels on top of the camera view.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({super.key, required this.detections});

  final List<DetectionResult> detections;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DetectionPainter(detections: detections),
        size: Size.infinite,
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter({required this.detections});

  final List<DetectionResult> detections;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromRGBO(0, 0, 0, 0.45);

    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        detection.rect.left * size.width,
        detection.rect.top * size.height,
        detection.rect.right * size.width,
        detection.rect.bottom * size.height,
      ).deflate(2);

      canvas.drawRect(rect, boxPaint);

      final textSpan = TextSpan(
        text:
            '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
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
      )..layout(maxWidth: size.width - 16);

      final labelRect = Rect.fromLTWH(
        rect.left,
        max(0.0, rect.top - tp.height - 6),
        tp.width + 12,
        tp.height + 8,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
        fillPaint,
      );
      tp.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
