// ---------------------------------------------------------------------------
// settings_screen.dart
// Modern settings screen for VisionMate AI.
// Organised into five sections: Appearance, Accessibility, Voice, Language,
// and About. Uses Switch widgets for toggleable preferences and SettingsTile
// for navigational rows. All state is local — no persistence in Module 2.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/section_header.dart';
import '../../widgets/settings_tile.dart';

/// The settings configuration screen for VisionMate AI.
///
/// Provides toggle-able and navigational settings across five thematic groups.
/// All [Switch] values are stored as local [State] and reset on hot-restart
/// since persistence is deferred to Module 4.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Appearance ────────────────────────────────────────────────────────────
  bool _darkMode = false;
  bool _highContrast = false;
  bool _largeText = false;

  // ── Accessibility ─────────────────────────────────────────────────────────
  bool _hapticFeedback = true;
  bool _screenReader = false;
  bool _reduceMotion = false;

  // ── Voice ─────────────────────────────────────────────────────────────────
  bool _voiceGuidance = true;
  bool _adjustedSpeechRate = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= AppConstants.tabletBreakpoint;

    return Scaffold(
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet
              ? AppConstants.screenPaddingTablet
              : AppConstants.screenPadding,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance Section ─────────────────────────────────────────
            const SectionHeader(title: AppStrings.appearanceSection),
            _SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF7B1FA2),
                  title: AppStrings.settingDarkMode,
                  subtitle: AppStrings.settingDarkModeSub,
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.contrast_rounded,
                  iconColor: const Color(0xFF1565C0),
                  title: AppStrings.settingHighContrast,
                  subtitle: AppStrings.settingHighContrastSub,
                  trailing: Switch(
                    value: _highContrast,
                    onChanged: (v) => setState(() => _highContrast = v),
                  ),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.text_increase_rounded,
                  iconColor: const Color(0xFF00695C),
                  title: AppStrings.settingLargeText,
                  subtitle: AppStrings.settingLargeTextSub,
                  trailing: Switch(
                    value: _largeText,
                    onChanged: (v) => setState(() => _largeText = v),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            // ── Accessibility Section ──────────────────────────────────────
            const SectionHeader(title: AppStrings.accessibilitySection),
            _SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.vibration_rounded,
                  iconColor: const Color(0xFFE65100),
                  title: AppStrings.settingHapticFeedback,
                  subtitle: AppStrings.settingHapticFeedbackSub,
                  trailing: Switch(
                    value: _hapticFeedback,
                    onChanged: (v) => setState(() => _hapticFeedback = v),
                  ),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.accessibility_new_rounded,
                  iconColor: const Color(0xFF1B5E20),
                  title: AppStrings.settingScreenReader,
                  subtitle: AppStrings.settingScreenReaderSub,
                  trailing: Switch(
                    value: _screenReader,
                    onChanged: (v) => setState(() => _screenReader = v),
                  ),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.motion_photos_off_rounded,
                  iconColor: const Color(0xFF37474F),
                  title: AppStrings.settingReduceMotion,
                  subtitle: AppStrings.settingReduceMotionSub,
                  trailing: Switch(
                    value: _reduceMotion,
                    onChanged: (v) => setState(() => _reduceMotion = v),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            // ── Voice Section ──────────────────────────────────────────────
            const SectionHeader(title: AppStrings.voiceSection),
            _SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.record_voice_over_rounded,
                  iconColor: const Color(0xFF0097A7),
                  title: AppStrings.settingVoiceGuidance,
                  subtitle: AppStrings.settingVoiceGuidanceSub,
                  trailing: Switch(
                    value: _voiceGuidance,
                    onChanged: (v) => setState(() => _voiceGuidance = v),
                  ),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF4527A0),
                  title: AppStrings.settingVoiceSpeed,
                  subtitle: AppStrings.settingVoiceSpeedSub,
                  trailing: Switch(
                    value: _adjustedSpeechRate,
                    onChanged: (v) => setState(() => _adjustedSpeechRate = v),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            // ── Language Section ───────────────────────────────────────────
            const SectionHeader(title: AppStrings.languageSection),
            _SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF1565C0),
                  title: AppStrings.settingLanguage,
                  subtitle: AppStrings.settingLanguageSub,
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.public_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  title: AppStrings.settingRegion,
                  subtitle: AppStrings.settingRegionSub,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            // ── About Section ──────────────────────────────────────────────
            const SectionHeader(title: AppStrings.aboutSection),
            _SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: const Color(0xFF1565C0),
                  title: AppStrings.settingPrivacy,
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF00695C),
                  title: AppStrings.settingTerms,
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.balance_rounded,
                  iconColor: const Color(0xFF37474F),
                  title: AppStrings.settingLicenses,
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: 56, height: 1),
                SettingsTile(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF9A825),
                  title: AppStrings.settingRate,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            // ── Version Info Footer ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${AppConstants.appVersion} · '
                      '${AppConstants.moduleVersion}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  /// Shows a brief SnackBar indicating the tapped setting is coming soon.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This setting will be available in a future module.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SettingsCard — a rounded card container for grouping settings tiles.
// ---------------------------------------------------------------------------

/// A card container that groups related [SettingsTile] widgets.
///
/// Applies consistent border, shadow, and background styling that matches the
/// Material 3 card theme.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.tileRadius),
        border: Border.all(
          color: colorScheme.outline.withAlpha(38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}
