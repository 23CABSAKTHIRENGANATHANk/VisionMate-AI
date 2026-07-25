// navigation_rules.dart
// Decision rules for VisionMate AI's navigation command engine.

import '../../spatial/models/navigation_object.dart';
import '../../spatial/models/spatial_enums.dart';
import 'navigation_command.dart';
import 'navigation_priority.dart';

/// Decision rule evaluator mapping spatial obstacle state into navigation commands.
class NavigationRules {
  const NavigationRules();

  static const Set<String> _irrelevantLabels = {
    'background',
    'floor',
    'sky',
    'wall',
    'ceiling',
    'plant',
    'book',
    'cup',
    'bottle',
  };

  /// Returns true when the object should be considered by the decision engine.
  bool isRelevant(NavigationObject obstacle) {
    final label = obstacle.label.toLowerCase().trim();
    if (obstacle.confidence < 0.35) {
      return false;
    }

    if (_irrelevantLabels.contains(label)) {
      return false;
    }

    if (obstacle.risk == RiskLevel.low &&
        obstacle.distance == ObjectDistance.far) {
      return false;
    }

    return true;
  }

  /// Returns the navigation command for the primary obstacle.
  NavigationCommand commandFor(NavigationObject obstacle) {
    final isLeft = obstacle.direction == ObjectDirection.left;
    final isRight = obstacle.direction == ObjectDirection.right;
    final isCenter = obstacle.direction == ObjectDirection.center;

    switch (obstacle.risk) {
      case RiskLevel.critical:
        if (isCenter) {
          return NavigationCommand.stop;
        }
        return isLeft
            ? NavigationCommand.moveRight
            : NavigationCommand.moveLeft;
      case RiskLevel.high:
        if (isCenter) {
          return NavigationCommand.slowDown;
        }
        return isLeft
            ? NavigationCommand.moveRight
            : NavigationCommand.moveLeft;
      case RiskLevel.medium:
        if (isCenter) {
          return NavigationCommand.goStraight;
        }
        return isLeft
            ? NavigationCommand.turnRight
            : NavigationCommand.turnLeft;
      case RiskLevel.low:
        if (isCenter) {
          return NavigationCommand.pathClear;
        }
        return isLeft
            ? NavigationCommand.turnRight
            : NavigationCommand.turnLeft;
    }
  }

  /// Converts a risk level to navigation priority metadata.
  NavigationPriority priorityFor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.critical:
        return NavigationPriority.critical;
      case RiskLevel.high:
        return NavigationPriority.high;
      case RiskLevel.medium:
        return NavigationPriority.medium;
      case RiskLevel.low:
        return NavigationPriority.low;
    }
  }
}
