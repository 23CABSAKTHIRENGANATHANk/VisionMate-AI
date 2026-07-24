// ---------------------------------------------------------------------------
// section_header.dart
// A reusable section title with an optional subtitle, used across Settings,
// Help, and any future screens requiring visual section demarcation.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// A styled section heading row with an optional [subtitle].
///
/// Provides consistent vertical spacing, typography, and an optional
/// leading colour accent bar to visually separate content groups.
///
/// Example:
/// ```dart
/// SectionHeader(title: 'Appearance', subtitle: 'Visual preferences')
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showAccent = true,
    this.topPadding = 24.0,
    this.bottomPadding = 8.0,
  });

  /// The primary heading text.
  final String title;

  /// Optional secondary description displayed below the title.
  final String? subtitle;

  /// Whether to display the leading vertical accent bar.
  final bool showAccent;

  /// Padding applied above the header row.
  final double topPadding;

  /// Padding applied below the header row.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Optional vertical accent bar on the leading edge.
          if (showAccent) ...[
            Container(
              width: 4,
              height: subtitle != null ? 36 : 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Title and optional subtitle stacked vertically.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
