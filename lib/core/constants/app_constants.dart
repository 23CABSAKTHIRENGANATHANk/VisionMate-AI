// ---------------------------------------------------------------------------
// app_constants.dart
// Global app-wide constants — route names, animation durations, spacing, and
// version information for the VisionMate AI experience.
// ---------------------------------------------------------------------------

/// Central repository of immutable application-level constants.
/// All magic strings, durations, and layout values live here to
/// ensure zero duplication across the codebase.
class AppConstants {
  // Private constructor — this is a pure-static utility class.
  AppConstants._();

  // ── App Identity ──────────────────────────────────────────────────────────

  /// Display name shown on Splash, AppBar, and About sections.
  static const String appName = 'VisionMate AI';

  /// Short tagline displayed on the Splash screen.
  static const String splashTagline =
      'AI Navigation Assistant for the Visually Impaired';

  /// Subtitle shown beneath the app name on the Home screen header.
  static const String homeSubtitle = 'Helping You Navigate Safely';

  /// Current application version string shown in Help > About.
  static const String appVersion = '2.0.0';

  /// Module version label for the About section.
  static const String moduleVersion = 'Full AI Navigation Pipeline';

  // ── Named Routes ──────────────────────────────────────────────────────────

  /// Route identifier for the Splash screen.
  static const String routeSplash = '/splash';

  /// Route identifier for the Home dashboard.
  static const String routeHome = '/home';

  /// Route identifier for the Camera placeholder.
  static const String routeCamera = '/camera';

  /// Route identifier for the Settings screen.
  static const String routeSettings = '/settings';

  /// Route identifier for the Help & Support screen.
  static const String routeHelp = '/help';

  /// Route identifier for the Navigation screen.
  static const String routeNavigation = '/navigation';

  // ── Timing ────────────────────────────────────────────────────────────────

  /// Duration the Splash screen is visible before auto-navigating to Home.
  static const Duration splashDuration = Duration(milliseconds: 2500);

  /// Duration of page transition animations.
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);

  /// Standard animation duration for card entrance effects.
  static const Duration cardAnimationDuration = Duration(milliseconds: 500);

  /// Stagger delay applied between each animated card on the Home screen.
  static const Duration cardStaggerDelay = Duration(milliseconds: 100);

  // ── Layout & Spacing ──────────────────────────────────────────────────────

  /// Default screen-edge horizontal padding in logical pixels.
  static const double screenPadding = 20.0;

  /// Larger screen padding used on wider (tablet) layouts.
  static const double screenPaddingTablet = 32.0;

  /// Standard gap used between major UI sections.
  static const double sectionGap = 24.0;

  /// Standard gap used between items within a section.
  static const double itemGap = 12.0;

  /// Border radius for feature cards and prominent containers.
  static const double cardRadius = 20.0;

  /// Border radius for smaller tiles and chips.
  static const double tileRadius = 14.0;

  /// Breakpoint (width in dp) above which tablet layout is activated.
  static const double tabletBreakpoint = 600.0;

  // ── Feature Card Labels ───────────────────────────────────────────────────

  /// Label for the Start Navigation feature card.
  static const String cardStartNavigation = 'Start Navigation';

  /// Subtitle for the Start Navigation feature card.
  static const String cardStartNavigationSub = 'Real-time route guidance';

  /// Label for the Camera Preview feature card.
  static const String cardCameraPreview = 'Camera Preview';

  /// Subtitle for the Camera Preview feature card.
  static const String cardCameraPreviewSub = 'Live object detection feed';

  /// Label for the Settings feature card.
  static const String cardSettings = 'Settings';

  /// Subtitle for the Settings feature card.
  static const String cardSettingsSub = 'Customise your experience';

  /// Label for the Help feature card.
  static const String cardHelp = 'Help & Support';

  /// Subtitle for the Help feature card.
  static const String cardHelpSub = 'Guides, FAQ, and contact';

  // ── Status Labels ─────────────────────────────────────────────────────────

  /// Status label shown when the camera hardware is detected and ready.
  static const String statusCameraReady = 'Camera Ready';

  /// Status label shown when voice synthesis is ready.
  static const String statusVoiceReady = 'Voice Ready';

  /// Status label shown when the AI model is not yet loaded.
  static const String statusAiNotLoaded = 'AI Not Loaded';

  /// Status label shown when the AI processing pipeline is loaded and ready.
  static const String statusAiReady = 'AI Pipeline Active';
}
