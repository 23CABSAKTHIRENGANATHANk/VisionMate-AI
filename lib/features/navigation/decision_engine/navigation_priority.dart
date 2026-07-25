// navigation_priority.dart
// Defines the priority outputs used by the VisionMate AI decision engine.

/// Overall severity level for navigation decisions.
enum NavigationPriority { critical, high, medium, low }

extension NavigationPriorityX on NavigationPriority {
  /// Returns a short, speech-friendly label for the priority.
  String get label {
    switch (this) {
      case NavigationPriority.critical:
        return 'Critical';
      case NavigationPriority.high:
        return 'High';
      case NavigationPriority.medium:
        return 'Medium';
      case NavigationPriority.low:
        return 'Low';
    }
  }
}
