import 'package:flutter/foundation.dart';

import '../features/detection/detection_result.dart';
import '../features/navigation/decision_engine/decision_engine.dart';
import '../features/spatial/spatial_processor.dart';
import '../models/navigation_data.dart';
import 'distance_estimator.dart';
import 'object_tracker.dart';
import 'obstacle_priority_analyzer.dart';
import 'path_analyzer.dart';
import 'position_analyzer.dart';



/// Central coordinator that executes the VisionMate AI processing pipeline:
///
/// Camera → AI Detection → Object Tracker (ByteTrack EMA) → Path Analyzer →
/// Scene Understanding → Position Analyzer → Distance Estimator → Speech Engine
class NavigationPipelineProcessor {
  NavigationPipelineProcessor({
    PositionAnalyzer? positionAnalyzer,
    DistanceEstimator? distanceEstimator,
    ObstaclePriorityAnalyzer? priorityAnalyzer,
    SpatialProcessor? spatialProcessor,
    DecisionEngine? decisionEngine,
    ObjectTracker? tracker,
    PathAnalyzer? pathAnalyzer,
  })  : _positionAnalyzer = positionAnalyzer ?? const PositionAnalyzer(),
        _distanceEstimator = distanceEstimator ?? const DistanceEstimator(),
        _priorityAnalyzer =
            priorityAnalyzer ?? const ObstaclePriorityAnalyzer(),
        _spatialProcessor = spatialProcessor ?? const SpatialProcessor(),
        _decisionEngine = decisionEngine ?? DecisionEngine(),
        _tracker = tracker ?? ObjectTracker(),
        _pathAnalyzer = pathAnalyzer ?? const PathAnalyzer();

  static final NavigationPipelineProcessor instance =
      NavigationPipelineProcessor();

  final PositionAnalyzer _positionAnalyzer;
  final DistanceEstimator _distanceEstimator;
  final ObstaclePriorityAnalyzer _priorityAnalyzer;
  final SpatialProcessor _spatialProcessor;
  final DecisionEngine _decisionEngine;
  final ObjectTracker _tracker;
  final PathAnalyzer _pathAnalyzer;

  bool _wasPathBlocked = false;

  /// Resets all stateful processing memory: object tracks, decision history,
  /// and path-blocked flag.
  ///
  /// Must be called when the camera switches or the app resumes from background
  /// to prevent stale tracks from a previous session from generating ghost
  /// navigation alerts ("Chair detected" when pointing at a blank wall).
  void reset() {
    _tracker.clear();
    _wasPathBlocked = false;
    if (kDebugMode) {
      debugPrint('[NavigationPipelineProcessor] Session reset. Tracks cleared.');
    }
  }


  NavigationData process(List<DetectionResult> rawDetections) {
    final startTime = DateTime.now();

    // 1. Calculate raw estimated distances for tracking association
    final rawDistances = rawDetections
        .map((d) => _distanceEstimator.estimate(d.label, d.rect))
        .toList();

    // 2. Track objects across frames with EMA coordinate & distance smoothing
    final tracked = _tracker.update(rawDetections, rawDistances);

    // 3. Path corridor clearance analysis
    final pathClearance = _pathAnalyzer.analyze(tracked);

    if (tracked.isEmpty) {
      // Only speak when transitioning from blocked → clear.
      // When there was never an obstacle (_wasPathBlocked == false),
      // stay completely silent — silence means all-clear for navigation.
      // This prevents the "Path clear. Continue straight." loop that fired
      // every 6 seconds even when pointing at a blank wall with no objects.
      final shouldSpeakClear = _wasPathBlocked;
      _wasPathBlocked = false;

      if (kDebugMode && shouldSpeakClear) {
        debugPrint('[Speech Log] Obstacle cleared → Path clear. Continue straight.');
      }

      return NavigationData(
        timestamp: DateTime.now(),
        obstacles: const <ProcessedObstacle>[],
        primaryObstacle: null,
        voiceGuidanceText: 'Path is clear.',
        shouldSpeak: shouldSpeakClear, // Only speak on blocked→clear transition
        hapticAlertLevel: HapticAlertLevel.none,
        pathState: PathState.clear,
      );
    }

    _wasPathBlocked = true;

    // 4. Process tracked objects into priority obstacle models
    final processedList = <ProcessedObstacle>[];
    for (final track in tracked) {
      final smoothedDetection = DetectionResult(
        label: track.label,
        confidence: track.confidence,
        rect: track.smoothedRect,
      );
      final position = _positionAnalyzer.analyze(track.smoothedRect);
      final distanceData = DistanceData(
        distanceMeters: track.smoothedDistance,
        category: _distanceCategory(track.smoothedDistance),
        formattedDistance: track.formattedDistance,
      );

      final processed = _priorityAnalyzer.evaluate(
        detection: smoothedDetection,
        position: position,
        distance: distanceData,
      );
      processedList.add(processed);
    }

    // 5. Rank obstacles: Select single highest collision-risk primary obstacle
    processedList.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    final primary = processedList.first;
    final primaryTrack = tracked.firstWhere(
      (t) => t.label.toLowerCase() == primary.detection.label.toLowerCase(),
      orElse: () => tracked.first,
    );

    // 6. Evaluate spatial decision and object memory speech criteria
    final navigationObjects = _spatialProcessor.process(
      processedList.map((p) => p.detection).toList(),
    );
    final decision = _decisionEngine.decideFrom(navigationObjects);

    final PathState pathState;
    final HapticAlertLevel hapticLevel;

    if (primary.priorityTier == ObstaclePriorityTier.critical ||
        primaryTrack.smoothedDistance < 0.6) {
      pathState = PathState.blocked;
      hapticLevel = HapticAlertLevel.urgent;
    } else if (primary.priorityTier == ObstaclePriorityTier.high) {
      pathState = PathState.caution;
      hapticLevel = HapticAlertLevel.warning;
    } else if (primary.priorityTier == ObstaclePriorityTier.medium) {
      pathState = PathState.caution;
      hapticLevel = HapticAlertLevel.subtle;
    } else {
      pathState = PathState.clear;
      hapticLevel = HapticAlertLevel.none;
    }

    // 7. Object Memory Speech Rule Evaluation
    final speechResult =
        _evaluateSpeechMemory(primaryTrack, primary, decision, pathClearance);

    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

    if (kDebugMode) {
      debugPrint(
        '[Navigation Log] Primary: #${primaryTrack.id} ${primary.label} (${primaryTrack.formattedDistance}) • Action: "${speechResult.guidanceText}" (Speak=${speechResult.shouldSpeak}) • Pipeline: ${elapsedMs}ms',
      );
    }

    return NavigationData(
      timestamp: DateTime.now(),
      obstacles: processedList,
      primaryObstacle: primary,
      voiceGuidanceText: speechResult.guidanceText,
      shouldSpeak: speechResult.shouldSpeak,
      hapticAlertLevel: hapticLevel,
      pathState: pathState,
    );
  }

  /// Evaluates object memory tracking rules to emit voice guidance only when meaningful changes occur.
  _SpeechEvaluationResult _evaluateSpeechMemory(
    TrackedObject track,
    ProcessedObstacle primary,
    NavigationDecision decision,
    PathClearance pathClearance,
  ) {
    final now = DateTime.now();
    final dist = track.smoothedDistance;
    final zone = primary.position.readableDirection;
    final label = track.label;

    final lastSpokenAt = track.lastSpokenAt;
    final lastDist = track.lastSpokenDistance;
    final lastZone = track.lastSpokenZone;

    // Emergency: Completely blocked space (< 30% clearance across all corridors)
    if (pathClearance.leftClearance < 0.30 &&
        pathClearance.centerClearance < 0.30 &&
        pathClearance.rightClearance < 0.30) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return _SpeechEvaluationResult(
        guidanceText: 'No safe path detected. Stop immediately.',
        shouldSpeak: true,
      );
    }

    // Emergency Interrupt Rule (< 0.6 meters)
    if (dist < 0.6) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      final text = label.toLowerCase() == 'person'
          ? 'Person ahead. Stop immediately.'
          : '$label ahead. Stop immediately.';
      return _SpeechEvaluationResult(
        guidanceText: text,
        shouldSpeak: true,
      );
    }

    final isApproaching = lastDist != null && (lastDist - dist) >= 0.35;

    // First time announcing this object
    if (lastSpokenAt == null || lastDist == null || lastZone == null) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return _SpeechEvaluationResult(
        guidanceText: _buildGuidanceSentence(label, zone, dist, pathClearance, isApproaching: isApproaching),
        shouldSpeak: true,
      );
    }

    // Delta checks
    final distDelta = (dist - lastDist).abs();
    final zoneChanged = zone != lastZone;
    final cooldownElapsed = now.difference(lastSpokenAt).inSeconds >= 3;

    if (label.toLowerCase() == 'person' && isApproaching) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return const _SpeechEvaluationResult(
        guidanceText: 'Person approaching.',
        shouldSpeak: true,
      );
    }

    if (zoneChanged) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return _SpeechEvaluationResult(
        guidanceText: _buildGuidanceSentence(label, zone, dist, pathClearance, isApproaching: false),
        shouldSpeak: true,
      );
    }

    if (distDelta >= 0.40) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return _SpeechEvaluationResult(
        guidanceText: _buildGuidanceSentence(label, zone, dist, pathClearance, isApproaching: false),
        shouldSpeak: true,
      );
    }

    if (cooldownElapsed) {
      track.lastSpokenAt = now;
      track.lastSpokenDistance = dist;
      track.lastSpokenZone = zone;
      return _SpeechEvaluationResult(
        guidanceText: _buildGuidanceSentence(label, zone, dist, pathClearance, isApproaching: false),
        shouldSpeak: decision.shouldSpeak,
      );
    }

    // Suppress repeated identical frame speech
    return _SpeechEvaluationResult(
      guidanceText: _buildGuidanceSentence(label, zone, dist, pathClearance, isApproaching: false),
      shouldSpeak: false,
    );
  }

  String _buildGuidanceSentence(
    String label,
    String zone,
    double distanceMeters,
    PathClearance pathClearance, {
    bool isApproaching = false,
  }) {
    final lowerLabel = label.toLowerCase().trim();

    // Person specific announcements
    if (lowerLabel == 'person') {
      if (isApproaching) {
        return 'Person approaching.';
      }
      if (zone.contains('left')) {
        return 'Person on your left.';
      }
      if (zone.contains('right')) {
        return 'Person on your right.';
      }
      return 'Person ahead.';
    }

    final spokenDist = distanceMeters < 1.0
        ? '${(distanceMeters * 100).round()} centimeters'
        : '${distanceMeters.toStringAsFixed(1)} meters';

    if (pathClearance.guidanceAction == 'Move left') {
      return '$label $zone at $spokenDist. Move left.';
    } else if (pathClearance.guidanceAction == 'Move right') {
      return '$label $zone at $spokenDist. Move right.';
    } else if (pathClearance.guidanceAction == 'Stop immediately') {
      return '$label $zone at $spokenDist. Stop immediately.';
    }

    return '$label $zone at $spokenDist.';
  }

  ProximityCategory _distanceCategory(double distanceMeters) {
    if (distanceMeters < 1.0) return ProximityCategory.immediate;
    if (distanceMeters < 3.0) return ProximityCategory.near;
    if (distanceMeters < 5.0) return ProximityCategory.medium;
    return ProximityCategory.far;
  }
}

class _SpeechEvaluationResult {
  const _SpeechEvaluationResult({
    required this.guidanceText,
    required this.shouldSpeak,
  });

  final String guidanceText;
  final bool shouldSpeak;
}
