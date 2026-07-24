// ---------------------------------------------------------------------------
// settings_tile.dart
// A styled, reusable settings row with icon, title, subtitle, and a
// configurable trailing widget (Switch, Arrow, text value, etc.).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// A premium settings list tile.
///
/// Combines a gradient icon container, a title, an optional subtitle, and a
/// configurable [trailing] widget into a single consistent row.
///
/// The entire tile is tappable via [onTap] (used for navigation-type tiles).
/// For toggle tiles, pass a [Switch] widget as [trailing] and leave [onTap]
/// null — the switch handles interaction independently.
///
/// Example (toggle):
/// ```dart
/// SettingsTile(
///   icon: Icons.dark_mode_rounded,
///   iconColor: Colors.purple,
///   title: AppStrings.settingDarkMode,
///   subtitle: AppStrings.settingDarkModeSub,
///   trailing: Switch(value: isDark, onChanged: (v) { ... }),
/// )
/// ```
///
/// Example (navigation):
/// ```dart
/// SettingsTile(
///   icon: Icons.language_rounded,
///   iconColor: Colors.blue,
///   title: 'Language',
///   onTap: () { ... },
/// )
/// ```
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// Icon displayed in the leading gradient container.
  final IconData icon;

  /// Background colour of the leading icon container.
  final Color iconColor;

  /// Primary title text.
  final String title;

  /// Optional secondary description below the title.
  final String? subtitle;

  /// Widget displayed on the trailing side of the tile (Switch, arrow, etc.).
  final Widget? trailing;

  /// Callback triggered when the tile is tapped. Null for toggle-only tiles.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: subtitle != null ? '$title: $subtitle' : title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              // Leading icon container with a solid colour background.
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),

              const SizedBox(width: 14),

              // Title and optional subtitle.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
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

              // Trailing widget — Switch, chevron, or value label.
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                // Show a chevron if the tile is tappable but has no trailing.
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withAlpha(102),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
