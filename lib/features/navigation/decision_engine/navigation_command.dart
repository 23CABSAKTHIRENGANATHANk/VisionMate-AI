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
  String get label {
    switch (this) {
      case NavigationCommand.stop:
        return 'STOP';
      case NavigationCommand.moveLeft:
        return 'MOVE LEFT';
      case NavigationCommand.moveRight:
        return 'MOVE RIGHT';
      case NavigationCommand.goStraight:
        return 'GO STRAIGHT';
      case NavigationCommand.slowDown:
        return 'SLOW DOWN';
      case NavigationCommand.pathClear:
        return 'PATH CLEAR';
      case NavigationCommand.turnLeft:
        return 'TURN LEFT';
      case NavigationCommand.turnRight:
        return 'TURN RIGHT';
      case NavigationCommand.wait:
        return 'WAIT';
    }
  }
}
