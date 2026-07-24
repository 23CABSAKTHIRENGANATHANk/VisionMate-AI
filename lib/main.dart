// ---------------------------------------------------------------------------
// main.dart
// Application entry point for VisionMate AI.
// Configures the MaterialApp with Material 3 theming, Google Fonts, and the
// centralised AppRouter for named-route navigation with page transitions.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Ensure Flutter binding is initialised before any platform channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode on phones; tablets support both orientations.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const VisionMateApp());
}

/// Root application widget for VisionMate AI.
///
/// Configures:
/// - Material 3 light and dark themes from [AppTheme].
/// - Named-route registry and animated transitions from [AppRouter].
/// - Splash screen as the initial route via [AppConstants.routeSplash].
class VisionMateApp extends StatelessWidget {
  const VisionMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── App Identity ─────────────────────────────────────────────────────
      title: AppConstants.appName,

      // Hide the debug banner in all builds for a professional look.
      debugShowCheckedModeBanner: false,

      // ── Theming ───────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Respects the system-level light/dark preference.
      themeMode: ThemeMode.system,

      // ── Navigation ────────────────────────────────────────────────────────
      // onGenerateRoute handles all named routes with animated transitions.
      // The routes map is intentionally omitted so every navigation uses the
      // custom fade+slide transition defined in AppRouter.
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Show the splash screen first on every cold start.
      initialRoute: AppConstants.routeSplash,
    );
  }
}
