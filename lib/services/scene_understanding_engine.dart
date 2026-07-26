import 'object_tracker.dart';
import 'path_analyzer.dart';

/// Environment scene types recognized by spatial contour and object configuration analysis.
enum EnvironmentSceneType {
  openSpace,
  corridor,
  roomEntrance,
  narrowPassage,
  generalIndoor,
}

/// Rich environment scene context descriptor.
class EnvironmentScene {
  const EnvironmentScene({
    required this.type,
    required this.description,
    required this.spokenAnnouncement,
  });

  final EnvironmentSceneType type;
  final String description;
  final String spokenAnnouncement;
}

/// Analyzes spatial configurations of tracked objects, lateral boundaries, and corridor clearance
/// to derive high-level environment scene understanding for blind visually impaired users.
class SceneUnderstandingEngine {
  const SceneUnderstandingEngine();

  /// Analyzes tracked objects and path clearance to determine environment scene context.
  EnvironmentScene analyze(
    List<TrackedObject> trackedObjects,
    PathClearance pathClearance,
  ) {
    // 1. Check for Open Space (> 85% clearance across all corridors)
    if (pathClearance.leftClearance > 0.85 &&
        pathClearance.centerClearance > 0.85 &&
        pathClearance.rightClearance > 0.85) {
      return const EnvironmentScene(
        type: EnvironmentSceneType.openSpace,
        description: 'Open space ahead with unobstructed walking paths.',
        spokenAnnouncement: 'Open space ahead.',
      );
    }

    // 2. Check for Room Entrance / Doorway
    final hasDoorway = trackedObjects.any(
      (o) =>
          o.label.toLowerCase() == 'doorway' ||
          o.label.toLowerCase() == 'door',
    );
    if (hasDoorway) {
      return const EnvironmentScene(
        type: EnvironmentSceneType.roomEntrance,
        description: 'Room entrance or doorway detected ahead.',
        spokenAnnouncement: 'Room entrance detected.',
      );
    }

    // 3. Check for Corridor (lateral boundaries on both left and right with open center)
    final hasLeftBoundary = trackedObjects.any((o) => o.smoothedRect.left < 0.25);
    final hasRightBoundary = trackedObjects.any((o) => o.smoothedRect.right > 0.75);

    if (hasLeftBoundary && hasRightBoundary && pathClearance.centerClearance > 0.60) {
      return const EnvironmentScene(
        type: EnvironmentSceneType.corridor,
        description: 'Enclosed walking corridor with lateral walls.',
        spokenAnnouncement: 'You are in a corridor.',
      );
    }

    // 4. Check for Narrow Passage
    if (pathClearance.centerClearance < 0.45 &&
        (pathClearance.leftClearance < 0.50 || pathClearance.rightClearance < 0.50)) {
      return const EnvironmentScene(
        type: EnvironmentSceneType.narrowPassage,
        description: 'Constricted narrow walking passage.',
        spokenAnnouncement: 'Narrow passage.',
      );
    }

    return const EnvironmentScene(
      type: EnvironmentSceneType.generalIndoor,
      description: 'Indoor room space with detected items.',
      spokenAnnouncement: 'Indoor space.',
    );
  }
}
