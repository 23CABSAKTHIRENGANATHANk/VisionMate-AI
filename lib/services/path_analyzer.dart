

import 'object_tracker.dart';

/// Spatial corridor segment representing a horizontal slice of the camera field of view.
enum PathCorridor { left, center, right }

/// Spatial clearance metrics evaluated across the visual field.
class PathClearance {
  const PathClearance({
    required this.leftClearance,
    required this.centerClearance,
    required this.rightClearance,
    required this.recommendedCorridor,
    required this.guidanceAction,
  });

  /// Fraction of left corridor unobstructed [0.0 - 1.0].
  final double leftClearance;

  /// Fraction of central corridor unobstructed [0.0 - 1.0].
  final double centerClearance;

  /// Fraction of right corridor unobstructed [0.0 - 1.0].
  final double rightClearance;

  /// Recommended spatial corridor for safe walking.
  final PathCorridor recommendedCorridor;

  /// Spoken action recommendation (e.g. "Continue straight", "Move left", "Move right").
  final String guidanceAction;
}

/// Evaluates spatial corridors (Left, Center, Right) across video frames to detect
/// open walking space and guide visually impaired users safely.
class PathAnalyzer {
  const PathAnalyzer();

  /// Analyzes tracked objects to calculate corridor clearance and optimal path recommendations.
  PathClearance analyze(List<TrackedObject> trackedObjects) {
    if (trackedObjects.isEmpty) {
      return const PathClearance(
        leftClearance: 1.0,
        centerClearance: 1.0,
        rightClearance: 1.0,
        recommendedCorridor: PathCorridor.center,
        guidanceAction: 'Continue straight',
      );
    }

    double leftObstacleWeight = 0.0;
    double centerObstacleWeight = 0.0;
    double rightObstacleWeight = 0.0;

    for (final obj in trackedObjects) {
      final rect = obj.smoothedRect;
      final distance = obj.smoothedDistance;

      // Obstacles closer than 4.0m contribute to corridor blockage weight
      if (distance >= 4.0) continue;
      final proximityWeight = (4.0 - distance) / 4.0;
      final boxArea = (rect.width * rect.height).clamp(0.01, 1.0);
      final weight = proximityWeight * boxArea * 3.0;

      final centerX = (rect.left + rect.right) / 2;

      if (centerX < 0.38) {
        leftObstacleWeight += weight;
      } else if (centerX > 0.62) {
        rightObstacleWeight += weight;
      } else {
        centerObstacleWeight += weight;
      }
    }

    final leftClearance = (1.0 - leftObstacleWeight).clamp(0.0, 1.0);
    final centerClearance = (1.0 - centerObstacleWeight).clamp(0.0, 1.0);
    final rightClearance = (1.0 - rightObstacleWeight).clamp(0.0, 1.0);

    PathCorridor recommended;
    String action;

    if (centerClearance >= 0.65) {
      recommended = PathCorridor.center;
      action = 'Continue straight';
    } else if (leftClearance >= rightClearance && leftClearance >= 0.50) {
      recommended = PathCorridor.left;
      action = 'Move left';
    } else if (rightClearance >= 0.50) {
      recommended = PathCorridor.right;
      action = 'Move right';
    } else {
      recommended = PathCorridor.center;
      action = 'Stop immediately';
    }

    return PathClearance(
      leftClearance: leftClearance,
      centerClearance: centerClearance,
      rightClearance: rightClearance,
      recommendedCorridor: recommended,
      guidanceAction: action,
    );
  }
}
