// ---------------------------------------------------------------------------
// app_strings.dart
// All user-visible strings for VisionMate AI in one place.
// Keeping strings centralised makes localisation easy in future modules.
// ---------------------------------------------------------------------------

/// Centralised user-facing strings for VisionMate AI.
///
/// Strings are grouped by screen / feature area and prefixed accordingly.
/// No string literals should appear directly in widget build methods.
class AppStrings {
  // Private constructor — pure-static utility class.
  AppStrings._();

  // ── Home Screen ───────────────────────────────────────────────────────────

  /// Bottom-navigation label for the Home tab.
  static const String navHome = 'Home';

  /// Bottom-navigation label for the Camera tab.
  static const String navCamera = 'Camera';

  /// Bottom-navigation label for the Settings tab.
  static const String navSettings = 'Settings';

  /// Bottom-navigation label for the Help tab.
  static const String navHelp = 'Help';

  /// Heading on the status card inside the Home screen.
  static const String statusCardTitle = 'System Status';

  /// Subtitle on the status card inside the Home screen.
  static const String statusCardSubtitle = 'Module 2 — UI Ready';

  // ── Camera Screen ─────────────────────────────────────────────────────────

  /// Title shown in the AppBar of the Camera placeholder screen.
  static const String cameraTitle = 'Camera Preview';

  /// Primary message on the camera placeholder.
  static const String cameraPlaceholderTitle = 'Camera Module';

  /// Supporting detail on the camera placeholder.
  static const String cameraPlaceholderBody =
      'Camera integration will be activated in Module 3.\n'
      'Object detection and real-time guidance\nwill be available then.';

  /// Badge label shown on the camera screen illustration.
  static const String cameraComingSoon = 'Coming in Module 3';

  // ── Settings Screen ───────────────────────────────────────────────────────

  /// AppBar title for the Settings screen.
  static const String settingsTitle = 'Settings';

  // Appearance section
  static const String appearanceSection = 'Appearance';
  static const String settingDarkMode = 'Dark Mode';
  static const String settingDarkModeSub = 'Switch between light and dark theme';
  static const String settingHighContrast = 'High Contrast';
  static const String settingHighContrastSub = 'Increase colour contrast for readability';
  static const String settingLargeText = 'Large Text';
  static const String settingLargeTextSub = 'Increase default font size throughout the app';

  // Accessibility section
  static const String accessibilitySection = 'Accessibility';
  static const String settingHapticFeedback = 'Haptic Feedback';
  static const String settingHapticFeedbackSub = 'Vibrate on navigation events';
  static const String settingScreenReader = 'Screen Reader Support';
  static const String settingScreenReaderSub = 'Optimise UI for TalkBack / VoiceOver';
  static const String settingReduceMotion = 'Reduce Motion';
  static const String settingReduceMotionSub = 'Minimise animations for motion sensitivity';

  // Voice section
  static const String voiceSection = 'Voice';
  static const String settingVoiceGuidance = 'Voice Guidance';
  static const String settingVoiceGuidanceSub = 'Spoken directions during navigation';
  static const String settingVoiceSpeed = 'Speech Rate';
  static const String settingVoiceSpeedSub = 'Adjust text-to-speech speed';

  // Language section
  static const String languageSection = 'Language';
  static const String settingLanguage = 'App Language';
  static const String settingLanguageSub = 'English (United States)';
  static const String settingRegion = 'Region';
  static const String settingRegionSub = 'United States';

  // About section
  static const String aboutSection = 'About';
  static const String settingPrivacy = 'Privacy Policy';
  static const String settingTerms = 'Terms of Service';
  static const String settingLicenses = 'Open Source Licenses';
  static const String settingRate = 'Rate VisionMate AI';

  // ── Help Screen ───────────────────────────────────────────────────────────

  /// AppBar title for the Help screen.
  static const String helpTitle = 'Help & Support';

  // Getting Started section
  static const String gettingStartedSection = 'Getting Started';
  static const String gettingStartedStep1Title = '1. Open the App';
  static const String gettingStartedStep1Body =
      'Launch VisionMate AI on your Android device. The app will '
      'initialise all sensors and load the AI model automatically.';
  static const String gettingStartedStep2Title = '2. Allow Permissions';
  static const String gettingStartedStep2Body =
      'Grant camera and microphone permissions when prompted. These are '
      'required for object detection and voice guidance.';
  static const String gettingStartedStep3Title = '3. Start Navigating';
  static const String gettingStartedStep3Body =
      'Tap "Start Navigation" on the Home screen. Point your camera in '
      'the direction you want to move — VisionMate AI will guide you.';

  // FAQ section
  static const String faqSection = 'Frequently Asked Questions';
  static const String faqQ1 = 'Does this app work offline?';
  static const String faqA1 =
      'Module 3 will support on-device AI inference, enabling full '
      'offline operation without an internet connection.';
  static const String faqQ2 = 'Which Android version is required?';
  static const String faqA2 =
      'VisionMate AI requires Android 8.0 (API 26) or later for optimal '
      'performance. Android 10+ is recommended for best results.';
  static const String faqQ3 = 'Is my camera data stored or uploaded?';
  static const String faqA3 =
      'No. All processing happens entirely on your device. No video or '
      'image data is ever sent to external servers.';
  static const String faqQ4 = 'How accurate is the object detection?';
  static const String faqA4 =
      'The AI model (integrated in Module 3) is trained on thousands of '
      'obstacle categories with 90%+ accuracy in typical indoor environments.';

  // Emergency section
  static const String emergencySection = 'Emergency Contact';
  static const String emergencyTitle = 'Emergency Helpline';
  static const String emergencySubtitle =
      'If you feel unsafe or need immediate assistance:';
  static const String emergencyNumber = '112';
  static const String emergencyNote =
      'Long-press the navigation button for 3 seconds to trigger an '
      'automatic emergency alert (available in Module 4).';

  // About section inside Help
  static const String aboutHelpSection = 'About VisionMate AI';
  static const String aboutDescription =
      'VisionMate AI is an open-source accessibility project designed to '
      'empower visually impaired users with AI-powered navigation. '
      'Built with Flutter and Material 3 for a premium, accessible experience.';
  static const String aboutDeveloper = 'Developed by the VisionMate Team';
  static const String aboutContact = 'support@visionmate.ai';
}
