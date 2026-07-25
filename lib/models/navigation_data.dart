import '../services/obstacle_priority_analyzer.dart';

/// Overall state of the user's forward walking path.
enum PathState {
  /// Path is clear of immediate obstacles.
  clear,

  /// Obstacles detected in vicinity; caution advised.
  caution,

  /// Path directly blocked by immediate obstacle.
  blocked,
}

/// Haptic alert feedback intensity level.
enum HapticAlertLevel {
  /// Rapid repeating pulses for imminent hazard.
  urgent,

  /// Moderate single pulse warning.
  warning,

  /// Subtle touch feedback.
  subtle,

  /// No haptic feedback required.
  none,
}

/// Final synthesized navigation payload ready for user consumption.
class NavigationData {
  const NavigationData({
    required this.timestamp,
    required this.obstacles,
    required this.primaryObstacle,
    required this.voiceGuidanceText,
    required this.shouldSpeak,
    required this.hapticAlertLevel,
    required this.pathState,
  });

  /// Timestamp when navigation calculation was completed.
  final DateTime timestamp;

  /// All processed obstacles sorted by priority score (highest score first).
  final List<ProcessedObstacle> obstacles;

  /// The highest priority obstacle requiring immediate user attention (if any).
  final ProcessedObstacle? primaryObstacle;

  /// Synthesized navigation command text.
  final String voiceGuidanceText;

  /// Whether this command should be emitted to voice output.
  final bool shouldSpeak;

  /// Current overall path state.
  final PathState pathState;

  /// Current haptic alert intensity.
  final HapticAlertLevel hapticAlertLevel;

  /// Total count of detected obstacles.
  int get obstacleCount => obstacles.length;

  /// Returns true if there are any detected obstacles.
  bool get hasObstacles => obstacles.isNotEmpty;

  /// Factory constructor for empty/clear navigation state.
  ///
  /// Note: [shouldSpeak] is intentionally [false] here. In the main pipeline,
  /// empty-detection "PATH CLEAR" announcements are produced by [DecisionEngine]
  /// (which applies the 3-second cooldown). This factory is kept as a safe
  /// fallback for callers that need a neutral NavigationData without triggering
  /// speech.
  factory NavigationData.clear() {
    return NavigationData(
      timestamp: DateTime.now(),
      obstacles: const <ProcessedObstacle>[],
      primaryObstacle: null,
      voiceGuidanceText: 'PATH CLEAR',
      shouldSpeak: false,
      hapticAlertLevel: HapticAlertLevel.none,
      pathState: PathState.clear,
    );
  }
}
