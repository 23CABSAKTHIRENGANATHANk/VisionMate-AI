// ---------------------------------------------------------------------------
// app_router.dart
// Centralised named-route registry with custom animated page transitions.
// All route names are sourced from AppConstants to prevent magic strings.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../features/camera/camera_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/navigation/navigation_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../constants/app_constants.dart';

/// Centralised router for VisionMate AI.
///
/// Provides:
/// - A static [routes] map for [MaterialApp.routes].
/// - A static [onGenerateRoute] callback for custom transitions.
///
/// All named routes are defined in [AppConstants] to avoid magic strings.
class AppRouter {
  // Private constructor — pure-static utility class.
  AppRouter._();

  /// Named-route map passed directly to [MaterialApp.routes].
  ///
  /// Splash and Home are registered here for simple pushReplacementNamed usage.
  /// All others are handled via [onGenerateRoute] for animated transitions.
  static Map<String, WidgetBuilder> get routes => {
        AppConstants.routeSplash: (_) => const SplashScreen(),
        AppConstants.routeHome: (_) => const HomeScreen(),
        AppConstants.routeCamera: (_) => const CameraScreen(),
        AppConstants.routeSettings: (_) => const SettingsScreen(),
        AppConstants.routeHelp: (_) => const HelpScreen(),
        AppConstants.routeNavigation: (_) => const NavigationScreen(),
      };

  /// Generates animated routes for any named route.
  ///
  /// Uses a combined fade + slight upward slide transition, providing a
  /// smooth, premium feel while remaining accessible (no jarring motion).
  ///
  /// Falls back to a simple [MaterialPageRoute] for unrecognised routes.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder == null) {
      // Unknown route — return a simple error screen rather than throwing.
      return MaterialPageRoute(
        builder: (_) => const _UnknownRouteScreen(),
        settings: settings,
      );
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          builder(context),
      transitionDuration: AppConstants.pageTransitionDuration,
      reverseTransitionDuration: AppConstants.pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + slide-up composite transition.
        const begin = Offset(0.0, 0.04);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _UnknownRouteScreen — shown when navigating to an unregistered route.
// ---------------------------------------------------------------------------

/// Fallback screen displayed when a navigation target cannot be resolved.
class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '404 — Page Not Found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This route has not been registered.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppConstants.routeHome,
                    (route) => false,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
