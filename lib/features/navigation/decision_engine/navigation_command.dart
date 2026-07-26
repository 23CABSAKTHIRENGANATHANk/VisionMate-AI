// navigation_command.dart
// Defines the command set used by VisionMate AI for spoken navigation guidance.

/// Canonical navigation commands produced by the decision engine.
enum NavigationCommand {
  stop,
  moveLeft,
  moveRight,
  goStraight,
  slowDown,
  pathClear,
  turnLeft,
  turnRight,
  wait,
}

extension NavigationCommandX on NavigationCommand {
  /// Human-readable label suitable for speech output.
  /// Written as calm, natural accessibility language — not uppercase commands.
  String get label {
    switch (this) {
      case NavigationCommand.stop:
        return 'Stop immediately.';
      case NavigationCommand.moveLeft:
        return 'Move slightly to the left.';
      case NavigationCommand.moveRight:
        return 'Move slightly to the right.';
      case NavigationCommand.goStraight:
        return 'Continue straight ahead.';
      case NavigationCommand.slowDown:
        return 'Slow down.';
      case NavigationCommand.pathClear:
        return 'Path is clear.';
      case NavigationCommand.turnLeft:
        return 'Turn left.';
      case NavigationCommand.turnRight:
        return 'Turn right.';
      case NavigationCommand.wait:
        return 'Please wait.';
    }
  }
}
