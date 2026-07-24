// ---------------------------------------------------------------------------
// feature_card.dart
// Premium gradient feature card used on the Home dashboard.
// Each card displays an icon, title, subtitle, and responds to taps with a
// Material ripple effect. Designed to be fully responsive.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'gradient_icon_container.dart';

/// A premium, gradient-backed card representing a major app feature.
///
/// Supports:
/// - Configurable [gradient] for unique colour identity per feature.
/// - [icon], [title], and [subtitle] for clear information hierarchy.
/// - Material ripple via [InkWell] with rounded corners.
/// - Semantic label for screen-reader accessibility.
/// - [onTap] callback for navigation.
///
/// Automatically constrains height to maintain a consistent grid layout.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.semanticLabel,
  });

  /// Gradient applied to the card's full background.
  final Gradient gradient;

  /// Icon displayed inside the [GradientIconContainer] atop the card.
  final IconData icon;

  /// Primary label — bold and prominent.
  final String title;

  /// Supporting detail displayed below the title.
  final String subtitle;

  /// Callback triggered when the card is tapped.
  final VoidCallback onTap;

  /// Optional semantic label for accessibility (TalkBack/VoiceOver).
  /// Defaults to "$title: $subtitle" if null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ?? '$title: $subtitle';

    return Semantics(
      label: effectiveSemanticLabel,
      button: true,
      child: Material(
        // Material wrapping is needed for the InkWell ripple to render on
        // top of the gradient background.
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withAlpha(30),
            highlightColor: Colors.white.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient icon container — visually anchors the card.
                  GradientIconContainer(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(40),
                        Colors.white.withAlpha(20),
                      ],
                    ),
                    icon: icon,
                    size: 52,
                    iconSize: 26,
                    iconColor: Colors.white,
                  ),

                  const Spacer(),

                  // Feature title.
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Feature subtitle.
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
