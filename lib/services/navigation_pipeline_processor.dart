import '../features/detection/detection_result.dart';
import '../features/navigation/decision_engine/decision_engine.dart';
import '../features/spatial/spatial_processor.dart';
import '../models/navigation_data.dart';
import 'distance_estimator.dart';
import 'obstacle_priority_analyzer.dart';
import 'position_analyzer.dart';

/// Central coordinator that executes the VisionMate AI processing pipeline:
///
/// Camera → AI Detection → Bounding Boxes → Position Analyzer → Distance Estimator → Obstacle Priority → Navigation Data
class NavigationPipelineProcessor {
  NavigationPipelineProcessor({
    PositionAnalyzer? positionAnalyzer,
    DistanceEstimator? distanceEstimator,
    ObstaclePriorityAnalyzer? priorityAnalyzer,
    SpatialProcessor? spatialProcessor,
    DecisionEngine? decisionEngine,
  }) : _positionAnalyzer = positionAnalyzer ?? const PositionAnalyzer(),
       _distanceEstimator = distanceEstimator ?? const DistanceEstimator(),
       _priorityAnalyzer = priorityAnalyzer ?? const ObstaclePriorityAnalyzer(),
       _spatialProcessor = spatialProcessor ?? const SpatialProcessor(),
       _decisionEngine = decisionEngine ?? DecisionEngine();

  static final NavigationPipelineProcessor instance =
      NavigationPipelineProcessor();

  final PositionAnalyzer _positionAnalyzer;
  final DistanceEstimator _distanceEstimator;
  final ObstaclePriorityAnalyzer _priorityAnalyzer;
  final SpatialProcessor _spatialProcessor;
  final DecisionEngine _decisionEngine;

  /// Processes raw bounding box detection results into complete [NavigationData].
  NavigationData process(List<DetectionResult> detections) {
    if (detections.isEmpty) {
      return NavigationData.clear();
    }

    final processedList = <ProcessedObstacle>[];
    for (final detection in detections) {
      final position = _positionAnalyzer.analyze(detection.rect);
      final distance = _distanceEstimator.estimate(
        detection.label,
        detection.rect,
      );
      final processed = _priorityAnalyzer.evaluate(
        detection: detection,
        position: position,
        distance: distance,
      );
      processedList.add(processed);
    }

    processedList.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    final primary = processedList.first;

    final navigationObjects = _spatialProcessor.process(detections);
    final decision = _decisionEngine.decideFrom(navigationObjects);

    final pathState;
    final hapticLevel;

    if (primary.priorityTier == ObstaclePriorityTier.critical) {
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

    return NavigationData(
      timestamp: DateTime.now(),
      obstacles: processedList,
      primaryObstacle: primary,
      voiceGuidanceText: decision.guidanceText,
      shouldSpeak: decision.shouldSpeak,
      hapticAlertLevel: hapticLevel,
      pathState: pathState,
    );
  }
}
