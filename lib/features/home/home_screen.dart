// ---------------------------------------------------------------------------
// home_screen.dart
// Main dashboard screen for VisionMate AI.
// Displays a gradient header, four animated feature cards in a responsive
// grid, a system status card, and a bottom navigation bar (placeholder).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_indicator.dart';

/// The primary dashboard screen of VisionMate AI.
///
/// Responsibilities:
/// - Shows the app identity header with a gradient banner.
/// - Renders a responsive 2-column grid of [FeatureCard]s with staggered
///   entrance animations.
/// - Shows a [_StatusCard] with live system status indicators.
/// - Provides a bottom [NavigationBar] (cosmetic placeholder for Module 3).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Currently selected bottom nav index (visual placeholder only).
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Use a two-column grid on phones and a three-column on tablets.
    final isTablet = size.width >= AppConstants.tabletBreakpoint;
    final horizontalPadding = isTablet
        ? AppConstants.screenPaddingTablet
        : AppConstants.screenPadding;

    return Scaffold(
      // ── Bottom Navigation Bar ──────────────────────────────────────────
      bottomNavigationBar: _buildBottomNavBar(),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: isTablet ? 200 : 180,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HomeHeader(isTablet: isTablet),
            ),
            // Collapsed state shows minimal app name in AppBar.
            title: const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),

          // ── Feature Card Grid ──────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppConstants.sectionGap,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section heading.
                  SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Tap a card to get started',
                    topPadding: 0,
                  ),

                  const SizedBox(height: AppConstants.itemGap),

                  // Responsive grid of feature cards.
                  _FeatureCardGrid(
                    crossAxisCount: isTablet ? 3 : 2,
                  ),

                  const SizedBox(height: AppConstants.sectionGap),

                  // System status card.
                  _StatusCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom navigation bar with four placeholder tabs.
  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedNavIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: AppStrings.navHome,
        ),
        NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt_rounded),
          label: AppStrings.navCamera,
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: AppStrings.navSettings,
        ),
        NavigationDestination(
          icon: Icon(Icons.help_outline_rounded),
          selectedIcon: Icon(Icons.help_rounded),
          label: AppStrings.navHelp,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeHeader — gradient banner with app identity text.
// ---------------------------------------------------------------------------

/// Gradient header widget displayed inside the [SliverAppBar] background.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isTablet
        ? AppConstants.screenPaddingTablet
        : AppConstants.screenPadding;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // App logo + name row.
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withAlpha(77),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 28 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -0.1, end: 0.0, duration: 500.ms),

              const SizedBox(height: 8),

              // Subtitle.
              Text(
                AppConstants.homeSubtitle,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideX(
                    begin: -0.1,
                    end: 0.0,
                    delay: 200.ms,
                    duration: 500.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeatureCardGrid — responsive animated grid of four feature cards.
// ---------------------------------------------------------------------------

/// A responsive grid of [FeatureCard] widgets with staggered entrance
/// animations. Each card is animated independently with an incremental delay.
class _FeatureCardGrid extends StatelessWidget {
  const _FeatureCardGrid({required this.crossAxisCount});

  /// Number of columns — 2 on phones, 3 on tablets.
  final int crossAxisCount;

  /// Data model for each feature card.
  static const List<_CardData> _cards = [
    _CardData(
      gradient: AppColors.navCardGradient,
      icon: Icons.navigation_rounded,
      title: AppConstants.cardStartNavigation,
      subtitle: AppConstants.cardStartNavigationSub,
      route: AppConstants.routeNavigation,
    ),
    _CardData(
      gradient: AppColors.cameraCardGradient,
      icon: Icons.camera_alt_rounded,
      title: AppConstants.cardCameraPreview,
      subtitle: AppConstants.cardCameraPreviewSub,
      route: AppConstants.routeCamera,
    ),
    _CardData(
      gradient: AppColors.settingsCardGradient,
      icon: Icons.settings_rounded,
      title: AppConstants.cardSettings,
      subtitle: AppConstants.cardSettingsSub,
      route: AppConstants.routeSettings,
    ),
    _CardData(
      gradient: AppColors.helpCardGradient,
      icon: Icons.help_rounded,
      title: AppConstants.cardHelp,
      subtitle: AppConstants.cardHelpSub,
      route: AppConstants.routeHelp,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Disable inner scrolling — parent CustomScrollView handles it.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.itemGap,
        mainAxisSpacing: AppConstants.itemGap,
        // Cards are slightly taller than wide for comfortable icon layout.
        childAspectRatio: 0.92,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];

        // Staggered animation — each card animates after the previous.
        final delay = AppConstants.cardStaggerDelay * index;

        return FeatureCard(
          gradient: card.gradient,
          icon: card.icon,
          title: card.title,
          subtitle: card.subtitle,
          onTap: () => Navigator.of(context).pushNamed(card.route),
        )
            .animate()
            .fadeIn(
              delay: delay + 300.ms,
              duration: AppConstants.cardAnimationDuration,
            )
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              delay: delay + 300.ms,
              duration: AppConstants.cardAnimationDuration,
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CardData — immutable data model for feature cards.
// ---------------------------------------------------------------------------

/// Immutable data holder for a single feature card configuration.
class _CardData {
  const _CardData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

// ---------------------------------------------------------------------------
// _StatusCard — system status display with animated indicators.
// ---------------------------------------------------------------------------

/// A card showing the current operational status of key app systems.
///
/// Displays three [StatusIndicator] rows:
/// - Camera status (ready in Module 2)
/// - Voice status (ready in Module 2)
/// - AI model status (not loaded until Module 3)
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: colorScheme.outline.withAlpha(38),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header row.
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.statusCardTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.statusCardSubtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Status indicator rows.
            StatusIndicator(
              label: AppConstants.statusCameraReady,
              status: IndicatorStatus.ready,
            ),
            const SizedBox(height: 12),
            StatusIndicator(
              label: AppConstants.statusVoiceReady,
              status: IndicatorStatus.ready,
            ),
            const SizedBox(height: 12),
            StatusIndicator(
              label: AppConstants.statusAiReady,
              status: IndicatorStatus.ready,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(
          begin: 0.1,
          end: 0.0,
          delay: 700.ms,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}
