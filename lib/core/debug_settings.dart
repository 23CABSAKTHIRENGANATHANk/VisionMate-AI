import 'package:flutter/foundation.dart';

/// Lightweight runtime debug settings toggles used during development.
///
/// These are intentionally kept in-memory and use `ValueNotifier` so UI can
/// react to changes without an external state management dependency.
class DebugSettings {
  DebugSettings._();

  static final ValueNotifier<bool> showDebugOverlay = ValueNotifier<bool>(
    false,
  );
}
