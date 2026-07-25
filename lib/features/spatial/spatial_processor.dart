import '../detection/detection_result.dart';
import 'analyzers/direction_analyzer.dart';
import 'analyzers/distance_estimator.dart';
import 'analyzers/risk_calculator.dart';
import 'models/navigation_object.dart';

/// Modular coordinator transforming raw [DetectionResult]s into spatial [NavigationObject]s.
class SpatialProcessor {
  const SpatialProcessor({
    DirectionAnalyzer? directionAnalyzer,
    DistanceEstimator? distanceEstimator,
    RiskCalculator? riskCalculator,
  })  : _directionAnalyzer = directionAnalyzer ?? const DirectionAnalyzer(),
        _distanceEstimator = distanceEstimator ?? const DistanceEstimator(),
        _riskCalculator = riskCalculator ?? const RiskCalculator();

  final DirectionAnalyzer _directionAnalyzer;
  final DistanceEstimator _distanceEstimator;
  final RiskCalculator _riskCalculator;

  /// Transforms raw object detection results into spatial navigation models.
  List<NavigationObject> process(List<DetectionResult> detections) {
    return detections.map((detection) {
      final direction = _directionAnalyzer.analyze(detection.rect);
      final distance = _distanceEstimator.estimate(detection.rect);
      final risk = _riskCalculator.calculate(
        label: detection.label,
        direction: direction,
        distance: distance,
        confidence: detection.confidence,
      );

      return NavigationObject.fromDetection(
        detection: detection,
        direction: direction,
        distance: distance,
        risk: risk,
      );
    }).toList();
  }
}
