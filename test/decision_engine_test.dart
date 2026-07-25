import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:visionmate_ai/features/navigation/decision_engine/decision_engine.dart';
import 'package:visionmate_ai/features/navigation/decision_engine/navigation_command.dart';
import 'package:visionmate_ai/features/navigation/decision_engine/navigation_rules.dart';
import 'package:visionmate_ai/features/navigation/decision_engine/navigation_priority.dart';
import 'package:visionmate_ai/features/spatial/models/navigation_object.dart';
import 'package:visionmate_ai/features/spatial/models/spatial_enums.dart';

void main() {
  group('NavigationRules', () {
    final rules = NavigationRules();

    test('ignores low-confidence and irrelevant objects', () {
      final object = NavigationObject(
        label: 'floor',
        confidence: 0.2,
        direction: ObjectDirection.center,
        distance: ObjectDistance.far,
        risk: RiskLevel.low,
        rect: Rect.fromLTWH(0.4, 0.4, 0.2, 0.2),
      );

      expect(rules.isRelevant(object), isFalse);
    });

    test('returns STOP for critical center obstacles', () {
      final object = NavigationObject(
        label: 'person',
        confidence: 0.9,
        direction: ObjectDirection.center,
        distance: ObjectDistance.near,
        risk: RiskLevel.critical,
        rect: Rect.fromLTWH(0.45, 0.25, 0.1, 0.3),
      );

      expect(rules.commandFor(object), NavigationCommand.stop);
    });

    test('returns TURN RIGHT for low left obstacles', () {
      final object = NavigationObject(
        label: 'chair',
        confidence: 0.95,
        direction: ObjectDirection.left,
        distance: ObjectDistance.far,
        risk: RiskLevel.low,
        rect: Rect.fromLTWH(0.1, 0.4, 0.2, 0.2),
      );

      expect(rules.commandFor(object), NavigationCommand.turnRight);
    });
  });

  group('DecisionEngine', () {
    late DateTime now;
    late DecisionEngine engine;

    setUp(() {
      now = DateTime(2026, 7, 26, 12, 0, 0);
      engine = DecisionEngine(
        repeatCooldown: const Duration(seconds: 3),
        timeProvider: () => now,
      );
    });

    test('selects highest risk obstacle and emits command-only guidance', () {
      final objects = [
        NavigationObject(
          label: 'person',
          confidence: 0.9,
          direction: ObjectDirection.left,
          distance: ObjectDistance.near,
          risk: RiskLevel.high,
          rect: Rect.fromLTWH(0.1, 0.4, 0.2, 0.5),
        ),
        NavigationObject(
          label: 'truck',
          confidence: 0.8,
          direction: ObjectDirection.center,
          distance: ObjectDistance.near,
          risk: RiskLevel.critical,
          rect: Rect.fromLTWH(0.45, 0.3, 0.2, 0.4),
        ),
      ];

      final decision = engine.decideFrom(objects);

      expect(decision.command, NavigationCommand.stop);
      expect(decision.guidanceText, 'STOP');
      expect(decision.priority, NavigationPriority.critical);
      expect(decision.shouldSpeak, isTrue);
    });

    test('suppresses duplicate command within cooldown for same obstacle', () {
      final object = NavigationObject(
        label: 'person',
        confidence: 0.9,
        direction: ObjectDirection.center,
        distance: ObjectDistance.near,
        risk: RiskLevel.critical,
        rect: Rect.fromLTWH(0.45, 0.3, 0.2, 0.4),
      );

      final firstDecision = engine.decideFrom([object]);
      expect(firstDecision.command, NavigationCommand.stop);
      expect(firstDecision.shouldSpeak, isTrue);

      final secondDecision = engine.decideFrom([object]);
      expect(secondDecision.command, NavigationCommand.stop);
      expect(secondDecision.shouldSpeak, isFalse);
    });

    test('repeats command after cooldown elapses', () {
      final object = NavigationObject(
        label: 'person',
        confidence: 0.9,
        direction: ObjectDirection.center,
        distance: ObjectDistance.near,
        risk: RiskLevel.critical,
        rect: Rect.fromLTWH(0.45, 0.3, 0.2, 0.4),
      );

      engine.decideFrom([object]);
      now = now.add(const Duration(seconds: 4));
      final nextDecision = engine.decideFrom([object]);

      expect(nextDecision.command, NavigationCommand.stop);
      expect(nextDecision.shouldSpeak, isTrue);
    });

    test('speaks again when direction changes even if same command', () {
      final leftObject = NavigationObject(
        label: 'person',
        confidence: 0.9,
        direction: ObjectDirection.left,
        distance: ObjectDistance.near,
        risk: RiskLevel.critical,
        rect: Rect.fromLTWH(0.1, 0.3, 0.2, 0.4),
      );
      final rightObject = NavigationObject(
        label: 'person',
        confidence: 0.9,
        direction: ObjectDirection.right,
        distance: ObjectDistance.near,
        risk: RiskLevel.critical,
        rect: Rect.fromLTWH(0.7, 0.3, 0.2, 0.4),
      );

      final firstDecision = engine.decideFrom([leftObject]);
      expect(firstDecision.command, NavigationCommand.moveRight);
      expect(firstDecision.shouldSpeak, isTrue);

      final secondDecision = engine.decideFrom([rightObject]);
      expect(secondDecision.command, NavigationCommand.moveLeft);
      expect(secondDecision.shouldSpeak, isTrue);
    });
  });
}
