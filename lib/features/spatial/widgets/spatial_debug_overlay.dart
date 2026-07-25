import 'dart:math';

import 'package:flutter/material.dart';

import '../models/navigation_object.dart';
import '../models/spatial_enums.dart';

/// Module 6 — Debug overlay rendering spatial understanding information
/// (Direction, Distance, Risk level) on top of camera preview.
class SpatialDebugOverlay extends StatelessWidget {
  const SpatialDebugOverlay({
    super.key,
    required this.objects,
    this.showGuideLines = true,
  });

  final List<NavigationObject> objects;
  final bool showGuideLines;

  @override
  Widget build(BuildContext context) {
    if (objects.isEmpty && !showGuideLines) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _SpatialDebugPainter(
              objects: objects,
              showGuideLines: showGuideLines,
            ),
            size: Size.infinite,
          ),
          if (objects.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: _buildDebugHud(context),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugHud(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'SPATIAL DEBUG OVERLAY (${objects.length} OBJECTS)',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: objects.take(3).map((obj) {
              final color = _getRiskColor(obj.risk);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  '${obj.label}: ${obj.direction.name} | ${obj.distance.name} | ${obj.risk.name.toUpperCase()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.critical:
        return const Color(0xFFFF3B30); // Red
      case RiskLevel.high:
        return const Color(0xFFFF9500); // Orange
      case RiskLevel.medium:
        return const Color(0xFFFFCC00); // Yellow
      case RiskLevel.low:
        return const Color(0xFF34C759); // Green
    }
  }
}

class _SpatialDebugPainter extends CustomPainter {
  _SpatialDebugPainter({
    required this.objects,
    required this.showGuideLines,
  });

  final List<NavigationObject> objects;
  final bool showGuideLines;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuideLines) {
      _drawSpatialGuideLines(canvas, size);
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromRGBO(0, 0, 0, 0.75);

    for (final object in objects) {
      final color = SpatialDebugOverlay._getRiskColor(object.risk);

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = object.risk == RiskLevel.critical ? 4.0 : 2.5
        ..color = color;

      final rect = Rect.fromLTRB(
        object.rect.left * size.width,
        object.rect.top * size.height,
        object.rect.right * size.width,
        object.rect.bottom * size.height,
      ).deflate(2);

      canvas.drawRect(rect, boxPaint);

      // Label details formatted: Label | Direction | Distance | Risk (Confidence%)
      final labelText =
          '${object.label} | ${object.direction.name} | ${object.distance.name} | ${object.risk.name.toUpperCase()} (${(object.confidence * 100).toStringAsFixed(0)}%)';

      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: max(120.0, size.width - 32));

      final labelRect = Rect.fromLTWH(
        rect.left,
        max(0.0, rect.top - tp.height - 8),
        tp.width + 12,
        tp.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        fillPaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        borderPaint,
      );

      tp.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 3));
    }
  }

  void _drawSpatialGuideLines(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white24;

    final leftX = size.width * 0.35;
    final rightX = size.width * 0.65;

    // Draw vertical guidelines dividing Left, Center, Right
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, size.height), guidePaint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, size.height), guidePaint);
  }

  @override
  bool shouldRepaint(covariant _SpatialDebugPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.showGuideLines != showGuideLines;
  }
}
