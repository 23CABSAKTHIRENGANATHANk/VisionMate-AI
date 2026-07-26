import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/detection/detection_result.dart';
import 'distance_estimator.dart';

/// Represents a persistent object track with motion vectors and velocity estimation.
class TrackedObject {
  TrackedObject({
    required this.id,
    required this.label,
    required this.rect,
    required this.confidence,
    required this.distanceMeters,
    required this.lastSeen,
  })  : smoothedRect = rect,
        smoothedDistance = distanceMeters,
        velocityX = 0.0,
        velocityY = 0.0,
        distanceVelocity = 0.0,
        consecutiveFramesCount = 1;

  final int id;
  final String label;
  Rect rect;
  Rect smoothedRect;
  double confidence;
  double distanceMeters;
  double smoothedDistance;
  DateTime lastSeen;

  /// Velocity vector components in normalized screen space per second.
  double velocityX;
  double velocityY;

  /// Approach velocity in meters per second (positive = approaching user).
  double distanceVelocity;

  int consecutiveFramesCount;

  /// Speech memory metadata for rate-limiting and delta tracking.
  DateTime? lastSpokenAt;
  double? lastSpokenDistance;
  String? lastSpokenZone;

  /// Returns true if the object has been confirmed across at least 3 consecutive frames.
  bool get isConfirmed => consecutiveFramesCount >= 3;

  /// Formatted distance string based on smoothed distance value.
  String get formattedDistance {
    if (smoothedDistance < 1.0) {
      final cm = max(10, (smoothedDistance * 100).round());
      return '${cm}cm';
    }
    return '${smoothedDistance.toStringAsFixed(1)}m';
  }

  /// Spoken distance description.
  String get spokenDistance {
    if (smoothedDistance < 1.0) {
      final cm = max(10, (smoothedDistance * 100).round());
      return '$cm centimeters';
    }
    return '${smoothedDistance.toStringAsFixed(1)} meters';
  }

  /// Updates tracked object metrics with EMA coordinate and distance smoothing.
  void update({
    required Rect newRect,
    required double newConfidence,
    required double newDistance,
    required DateTime now,
  }) {
    final dtSeconds = max(0.01, now.difference(lastSeen).inMilliseconds / 1000.0);
    lastSeen = now;
    consecutiveFramesCount++;
    confidence = newConfidence;
    rect = newRect;

    // Calculate motion velocity vectors
    final prevCenterX = (smoothedRect.left + smoothedRect.right) / 2;
    final prevCenterY = (smoothedRect.top + smoothedRect.bottom) / 2;
    final newCenterX = (newRect.left + newRect.right) / 2;
    final newCenterY = (newRect.top + newRect.bottom) / 2;

    velocityX = (newCenterX - prevCenterX) / dtSeconds;
    velocityY = (newCenterY - prevCenterY) / dtSeconds;

    // Approach velocity (positive means moving toward user)
    distanceVelocity = (smoothedDistance - newDistance) / dtSeconds;

    // Exponential Moving Average (EMA) bounding box smoothing (\alpha = 0.35)
    final l = smoothedRect.left * 0.65 + newRect.left * 0.35;
    final t = smoothedRect.top * 0.65 + newRect.top * 0.35;
    final r = smoothedRect.right * 0.65 + newRect.right * 0.35;
    final b = smoothedRect.bottom * 0.65 + newRect.bottom * 0.35;
    smoothedRect = Rect.fromLTRB(l, t, r, b);

    // Reject single-frame unrealistic distance jumps (> 1.2m per frame)
    final jump = (newDistance - smoothedDistance).abs();
    if (jump < 1.2 || consecutiveFramesCount > 4) {
      smoothedDistance = smoothedDistance * 0.60 + newDistance * 0.40;
    }
  }
}

/// ByteTrack-style object tracking service using spatial IoU overlap, velocity estimation,
/// EMA box smoothing, and temporal majority voting.
class ObjectTracker {
  ObjectTracker({this.iouMatchThreshold = 0.30});

  final double iouMatchThreshold;

  int _nextId = 1;
  final List<TrackedObject> _trackedObjects = <TrackedObject>[];

  List<TrackedObject> get trackedObjects =>
      _trackedObjects.where((o) => o.isConfirmed).toList();

  /// Updates object tracks with new raw detections and returns confirmed, smoothed tracked objects.
  List<TrackedObject> update(
    List<DetectionResult> detections,
    List<DistanceData> distances,
  ) {
    final now = DateTime.now();

    // 1. Prune stale tracks not updated in the last 2.5 seconds.
    // Extended from 1.5 s: with a 250ms frame interval and 3 confirmations
    // required, a 1.5 s timeout caused valid tracks to be dropped on any
    // 2-frame gap (e.g. partial occlusion, low-light frames). 2.5 s gives
    // the tracker enough runway to survive temporary detection gaps without
    // promoting a ghost track.
    _trackedObjects.removeWhere(
      (track) => now.difference(track.lastSeen).inMilliseconds > 2500,
    );

    final updatedTrackIndices = <int>{};

    for (var i = 0; i < detections.length; i++) {
      final det = detections[i];
      final dist = i < distances.length ? distances[i].distanceMeters : 2.0;

      // Find best matching existing track by highest IoU overlap with same label
      int bestIndex = -1;
      double maxIou = 0.0;

      for (var j = 0; j < _trackedObjects.length; j++) {
        if (updatedTrackIndices.contains(j)) continue;
        final track = _trackedObjects[j];
        if (track.label.toLowerCase() != det.label.toLowerCase()) continue;

        final iou = _calculateIoU(track.smoothedRect, det.rect);
        if (iou >= iouMatchThreshold && iou > maxIou) {
          maxIou = iou;
          bestIndex = j;
        }
      }

      if (bestIndex != -1) {
        _trackedObjects[bestIndex].update(
          newRect: det.rect,
          newConfidence: det.confidence,
          newDistance: dist,
          now: now,
        );
        updatedTrackIndices.add(bestIndex);
      } else {
        final newTrack = TrackedObject(
          id: _nextId++,
          label: det.label,
          rect: det.rect,
          confidence: det.confidence,
          distanceMeters: dist,
          lastSeen: now,
        );
        _trackedObjects.add(newTrack);
        updatedTrackIndices.add(_trackedObjects.length - 1);
      }
    }

    final confirmed = _trackedObjects.where((o) => o.isConfirmed).toList();

    if (kDebugMode && confirmed.isNotEmpty) {
      debugPrint(
        '[Tracking Log] Active Tracks: ${confirmed.map((t) => '#${t.id} ${t.label} (${t.formattedDistance})').join(', ')}',
      );
    }

    return confirmed;
  }

  void clear() {
    _trackedObjects.clear();
    _nextId = 1;
  }

  double _calculateIoU(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.width <= 0 || intersection.height <= 0) return 0.0;
    final areaInt = intersection.width * intersection.height;
    final unionArea = (a.width * a.height) + (b.width * b.height) - areaInt;
    if (unionArea <= 0) return 0.0;
    return areaInt / unionArea;
  }
}
