// decision_engine.dart
// Core decision engine for VisionMate AI navigation guidance.

import 'dart:ui';

import '../../spatial/models/navigation_object.dart';
import '../../spatial/models/spatial_enums.dart';
import 'navigation_command.dart';
import 'navigation_priority.dart';
import 'navigation_rules.dart';

/// A single navigation decision result produced by the decision engine.
class NavigationDecision {
  NavigationDecision({
    required this.command,
    required this.priority,
    required this.obstacle,
    required this.shouldSpeak,
  });

  /// The command spoken to the user.
  final NavigationCommand command;

  /// The decision priority level.
  final NavigationPriority priority;

  /// The primary spatial obstacle that triggered this decision.
  final NavigationObject obstacle;

  /// Whether the command should be emitted to voice output.
  final bool shouldSpeak;

  /// Spoken guidance text for the command.
  String get guidanceText => command.label;
}

/// Decision engine that converts spatial navigation objects into commands.
class DecisionEngine {
  DecisionEngine({
    NavigationRules? rules,
    this._repeatCooldown = const Duration(seconds: 6),
    DateTime Function()? timeProvider,
  }) : _rules = rules ?? const NavigationRules(),
       _timeProvider = timeProvider ?? DateTime.now;

  final NavigationRules _rules;
  final Duration _repeatCooldown;
  final DateTime Function() _timeProvider;

  NavigationCommand? _lastCommand;
  ObjectDirection? _lastDirection;
  String? _lastLabel;
  DateTime _lastDecisionAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Decides the most important action based on detected spatial obstacles.
  NavigationDecision decideFrom(List<NavigationObject> obstacles) {
    if (obstacles.isEmpty) {
      final command = NavigationCommand.pathClear;
      final decision = NavigationDecision(
        command: command,
        priority: NavigationPriority.low,
        obstacle: _emptyNavigationObject(),
        shouldSpeak: _shouldSpeak(command, _emptyNavigationObject()),
      );
      _updateHistoryIfNeeded(decision);
      return decision;
    }

    final relevantObstacles = obstacles.where(_rules.isRelevant).toList();
    if (relevantObstacles.isEmpty) {
      final command = NavigationCommand.pathClear;
      final decision = NavigationDecision(
        command: command,
        priority: NavigationPriority.low,
        obstacle: _emptyNavigationObject(),
        shouldSpeak: _shouldSpeak(command, _emptyNavigationObject()),
      );
      _updateHistoryIfNeeded(decision);
      return decision;
    }

    final primary = _selectPrimaryObstacle(relevantObstacles);
    final command = _rules.commandFor(primary);
    final priority = _rules.priorityFor(primary.risk);
    final shouldSpeak = _shouldSpeak(command, primary);

    final decision = NavigationDecision(
      command: command,
      priority: priority,
      obstacle: primary,
      shouldSpeak: shouldSpeak,
    );

    _updateHistoryIfNeeded(decision);
    return decision;
  }

  NavigationObject _selectPrimaryObstacle(List<NavigationObject> obstacles) {
    final byRisk = <RiskLevel, List<NavigationObject>>{};
    for (final obstacle in obstacles) {
      byRisk.putIfAbsent(obstacle.risk, () => []).add(obstacle);
    }

    final highestRisk = byRisk.keys.reduce((a, b) => a.index > b.index ? a : b);
    final candidates = byRisk[highestRisk]!;

    candidates.sort((a, b) {
      final directionScore = _directionScore(
        a.direction,
      ).compareTo(_directionScore(b.direction));
      if (directionScore != 0) {
        return directionScore;
      }

      final distanceScore = _distanceScore(
        a.distance,
      ).compareTo(_distanceScore(b.distance));
      if (distanceScore != 0) {
        return distanceScore;
      }

      return b.confidence.compareTo(a.confidence);
    });

    return candidates.first;
  }

  bool _shouldSpeak(NavigationCommand command, NavigationObject obstacle) {
    final now = _timeProvider();

    if (_lastCommand == null) {
      return true;
    }

    if (command != _lastCommand) {
      return true;
    }

    if (obstacle.direction != _lastDirection) {
      return true;
    }

    if (obstacle.label != _lastLabel) {
      return true;
    }

    return now.difference(_lastDecisionAt) > _repeatCooldown;
  }

  void _updateHistoryIfNeeded(NavigationDecision decision) {
    if (!decision.shouldSpeak) {
      return;
    }

    _lastCommand = decision.command;
    _lastDirection = decision.obstacle.direction;
    _lastLabel = decision.obstacle.label;
    _lastDecisionAt = _timeProvider();
  }

  int _directionScore(ObjectDirection direction) {
    switch (direction) {
      case ObjectDirection.center:
        return 0;
      case ObjectDirection.left:
      case ObjectDirection.right:
        return 1;
    }
  }

  int _distanceScore(ObjectDistance distance) {
    switch (distance) {
      case ObjectDistance.near:
        return 0;
      case ObjectDistance.medium:
        return 1;
      case ObjectDistance.far:
        return 2;
    }
  }

  NavigationObject _emptyNavigationObject() {
    return const NavigationObject(
      label: 'none',
      confidence: 0.0,
      direction: ObjectDirection.center,
      distance: ObjectDistance.far,
      risk: RiskLevel.low,
      rect: Rect.fromLTWH(0, 0, 0, 0),
    );
  }
}
