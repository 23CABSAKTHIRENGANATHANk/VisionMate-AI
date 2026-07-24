// ---------------------------------------------------------------------------
// help_screen.dart
// Help & Support screen for VisionMate AI.
// Contains four sections: Getting Started, FAQ, Emergency Contact, and
// About VisionMate AI. Uses HelpCard for expandable FAQ items.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/help_card.dart';
import '../../widgets/section_header.dart';

/// The Help & Support screen for VisionMate AI.
///
/// Organised into four sections:
/// 1. Getting Started — three-step onboarding guide.
/// 2. FAQ — four expandable question/answer cards.
/// 3. Emergency Contact — prominent emergency helpline card.
/// 4. About VisionMate AI — description, developer info, and version.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          AppStrings.helpTitle,
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
            // ── Getting Started ────────────────────────────────────────────
            const SectionHeader(title: AppStrings.gettingStartedSection)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms),

            _GettingStartedCard(
              stepTitle: AppStrings.gettingStartedStep1Title,
              stepBody: AppStrings.gettingStartedStep1Body,
              stepColor: colorScheme.primary,
              stepNumber: 1,
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: AppConstants.itemGap),

            _GettingStartedCard(
              stepTitle: AppStrings.gettingStartedStep2Title,
              stepBody: AppStrings.gettingStartedStep2Body,
              stepColor: colorScheme.secondary,
              stepNumber: 2,
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

            const SizedBox(height: AppConstants.itemGap),

            _GettingStartedCard(
              stepTitle: AppStrings.gettingStartedStep3Title,
              stepBody: AppStrings.gettingStartedStep3Body,
              stepColor: const Color(0xFF43A047),
              stepNumber: 3,
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

            // ── FAQ ────────────────────────────────────────────────────────
            const SectionHeader(title: AppStrings.faqSection)
                .animate()
                .fadeIn(delay: 450.ms, duration: 400.ms),

            HelpCard(
              title: AppStrings.faqQ1,
              body: AppStrings.faqA1,
              icon: Icons.wifi_off_rounded,
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            HelpCard(
              title: AppStrings.faqQ2,
              body: AppStrings.faqA2,
              icon: Icons.phone_android_rounded,
            ).animate().fadeIn(delay: 560.ms, duration: 400.ms),

            HelpCard(
              title: AppStrings.faqQ3,
              body: AppStrings.faqA3,
              icon: Icons.security_rounded,
            ).animate().fadeIn(delay: 620.ms, duration: 400.ms),

            HelpCard(
              title: AppStrings.faqQ4,
              body: AppStrings.faqA4,
              icon: Icons.precision_manufacturing_rounded,
            ).animate().fadeIn(delay: 680.ms, duration: 400.ms),

            // ── Emergency Contact ──────────────────────────────────────────
            const SectionHeader(title: AppStrings.emergencySection)
                .animate()
                .fadeIn(delay: 740.ms, duration: 400.ms),

            _EmergencyCard()
                .animate()
                .fadeIn(delay: 800.ms, duration: 400.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  delay: 800.ms,
                  duration: 400.ms,
                ),

            // ── About VisionMate AI ────────────────────────────────────────
            const SectionHeader(title: AppStrings.aboutHelpSection)
                .animate()
                .fadeIn(delay: 900.ms, duration: 400.ms),

            _AboutCard()
                .animate()
                .fadeIn(delay: 950.ms, duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GettingStartedCard — numbered step card for the onboarding guide.
// ---------------------------------------------------------------------------

/// A card displaying a numbered step with a title and description.
class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard({
    required this.stepNumber,
    required this.stepTitle,
    required this.stepBody,
    required this.stepColor,
  });

  final int stepNumber;
  final String stepTitle;
  final String stepBody;
  final Color stepColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number badge.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stepColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    color: stepColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Step content.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stepBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(178),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmergencyCard — prominent emergency helpline display card.
// ---------------------------------------------------------------------------

/// A high-contrast card displaying the emergency contact number and info.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row.
            Row(
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.emergencyTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtitle.
            Text(
              AppStrings.emergencySubtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            // Emergency number — large and prominent.
            Text(
              AppStrings.emergencyNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 12),

            // Note about future auto-alert feature.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.emergencyNote,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AboutCard — app description and developer info card.
// ---------------------------------------------------------------------------

/// A card showing the app description, developer info, contact, and version.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name + version badge row.
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'v${AppConstants.appVersion} — '
                        '${AppConstants.moduleVersion}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Description.
            Text(
              AppStrings.aboutDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(204),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 16),

            // Developer row.
            _InfoRow(
              icon: Icons.code_rounded,
              text: AppStrings.aboutDeveloper,
            ),

            const SizedBox(height: 8),

            // Contact row.
            _InfoRow(
              icon: Icons.email_outlined,
              text: AppStrings.aboutContact,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoRow — icon + text row used inside the About card.
// ---------------------------------------------------------------------------

/// A compact row pairing a [Material Icons] icon with a text value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(178),
            ),
          ),
        ),
      ],
    );
  }
}
