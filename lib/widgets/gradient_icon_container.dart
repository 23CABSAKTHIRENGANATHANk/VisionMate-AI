// ---------------------------------------------------------------------------
// gradient_icon_container.dart
// A rounded square container with a gradient background holding an icon.
// Used in feature cards and as the app logo placeholder on the Splash screen.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// A gradient rounded-rectangle box with a centred [icon].
///
/// Used consistently as the visual anchor for feature cards, section headers,
/// and the Splash screen logo. All gradient and sizing parameters are
/// configurable to support the diverse card styles on the Home screen.
///
/// Example:
/// ```dart
/// GradientIconContainer(
///   gradient: AppColors.navCardGradient,
///   icon: Icons.navigation_rounded,
///   size: 56,
///   iconSize: 28,
/// )
/// ```
class GradientIconContainer extends StatelessWidget {
  const GradientIconContainer({
    super.key,
    required this.gradient,
    required this.icon,
    this.size = 56.0,
    this.iconSize = 28.0,
    this.borderRadius = 16.0,
    this.iconColor = Colors.white,
  });

  /// The gradient applied to the container background.
  final Gradient gradient;

  /// The icon displayed in the centre of the container.
  final IconData icon;

  /// The width and height of the square container in logical pixels.
  final double size;

  /// The size of the icon in logical pixels.
  final double iconSize;

  /// Corner radius of the rounded rectangle container.
  final double borderRadius;

  /// Colour of the icon — defaults to white for contrast on gradients.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        // Soft shadow to lift the icon off the card surface.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
