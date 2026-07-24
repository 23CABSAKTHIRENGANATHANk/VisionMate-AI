// ---------------------------------------------------------------------------
// custom_button.dart
// Reusable, accessible filled button with optional icon.
// Enhanced for Module 2 with full-width layout and consistent styling.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// A full-width [FilledButton] with an optional leading [icon].
///
/// Provides a consistent call-to-action button used throughout VisionMate AI.
/// The button stretches to fill its parent's width by default.
///
/// Example:
/// ```dart
/// CustomButton(
///   label: 'Start Navigation',
///   icon: Icons.navigation_rounded,
///   onPressed: () { ... },
/// )
/// ```
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// The text label displayed inside the button.
  final String label;

  /// Callback triggered when the button is pressed.
  final VoidCallback onPressed;

  /// Optional leading icon. If null, the button renders label-only.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : FilledButton(
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }
}
