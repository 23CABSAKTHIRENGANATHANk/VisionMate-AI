import '../models/spatial_enums.dart';

/// Modular risk calculator that evaluates object direction, distance,
/// label hazard severity, and detection confidence to determine risk level.
class RiskCalculator {
  const RiskCalculator();

  /// Critical physical hazard object classes.
  static const Set<String> _criticalClasses = {
    'stairs',
    'hole',
    'step',
    'car',
    'truck',
    'bus',
  };

  /// High-risk obstacle object classes.
  static const Set<String> _highRiskClasses = {
    'person',
    'dog',
    'bicycle',
    'motorcycle',
    'door',
  };

  /// Calculates [RiskLevel] (low, medium, high, critical) for a detected object.
  RiskLevel calculate({
    required String label,
    required ObjectDirection direction,
    required ObjectDistance distance,
    required double confidence,
  }) {
    final labelLower = label.toLowerCase().trim();
    final isCriticalClass = _criticalClasses.contains(labelLower);
    final isHighClass = _highRiskClasses.contains(labelLower);
    final isCenter = direction == ObjectDirection.center;

    if (distance == ObjectDistance.near) {
      if (isCenter || isCriticalClass) {
        return RiskLevel.critical;
      }
      return RiskLevel.high;
    }

    if (distance == ObjectDistance.medium) {
      if (isCriticalClass && isCenter) {
        return RiskLevel.critical;
      }
      if (isCenter || isHighClass || isCriticalClass) {
        return RiskLevel.high;
      }
      return RiskLevel.medium;
    }

    // Far distance
    if (isCriticalClass && isCenter) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }
}
