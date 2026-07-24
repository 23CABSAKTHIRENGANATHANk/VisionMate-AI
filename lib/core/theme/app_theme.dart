// ---------------------------------------------------------------------------
// app_theme.dart
// Full Material 3 theme configuration for VisionMate AI.
// Uses Google Fonts (Inter for body, Outfit for display / headlines).
// Defines light and dark themes with matching colour schemes, card themes,
// appBar styles, bottom navigation, and text themes.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Central theme provider for VisionMate AI.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
/// )
/// ```
class AppTheme {
  // Private constructor — this is a pure-static utility class.
  AppTheme._();

  // ── Colour Schemes ────────────────────────────────────────────────────────

  /// Material 3 colour scheme for light mode, seeded from the brand blue.
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.teal,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
  );

  /// Material 3 colour scheme for dark mode.
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryLight,
    secondary: AppColors.tealLight,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
  );

  // ── Text Themes ───────────────────────────────────────────────────────────

  /// Returns a [TextTheme] using Outfit for display/headline sizes and
  /// Inter for body/label sizes — both loaded via Google Fonts.
  ///
  /// [baseColor] is the primary text colour for the current brightness.
  static TextTheme _buildTextTheme(Color baseColor) {
    final outfitTheme = GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),
    );

    // Body and label sizes use Inter for superior legibility at small sizes.
    return outfitTheme.copyWith(
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: baseColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: baseColor,
      ),
    );
  }

  // ── Shared Component Themes ────────────────────────────────────────────────

  /// Builds the card surface decoration applied inside [ThemeData].
  /// Uses a [RoundedRectangleBorder] with 20 dp corners consistent with the
  /// overall Material 3 rounded aesthetic.
  static Color _cardColor(Color surfaceColor) => surfaceColor;

  /// Builds the [AppBarTheme] for the given colour scheme.
  static AppBarTheme _buildAppBarTheme(ColorScheme scheme) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      systemOverlayStyle: scheme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
  }

  /// Builds the [BottomNavigationBarThemeData] for the given colour scheme.
  static BottomNavigationBarThemeData _buildBottomNavTheme(
    ColorScheme scheme,
  ) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurface.withAlpha(102),
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      elevation: 8,
      showUnselectedLabels: true,
    );
  }

  // ── Exported Themes ────────────────────────────────────────────────────────

  /// Full Material 3 light theme for VisionMate AI.
  static ThemeData get lightTheme {
    final scheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildTextTheme(AppColors.textPrimaryLight),
      // Card colour is applied via a theme extension so we avoid the
      // CardTheme / CardThemeData version mismatch across Flutter SDK builds.
      appBarTheme: _buildAppBarTheme(scheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(scheme),

      // Dividers and list tiles
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withAlpha(51);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      // Filled button style
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Elevated button style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Extensions carry the card surface colour in a version-safe way.
      extensions: <ThemeExtension<dynamic>>[
        _AppCardTheme(surfaceColor: _cardColor(AppColors.surfaceLight)),
      ],
    );
  }

  /// Full Material 3 dark theme for VisionMate AI.
  static ThemeData get darkTheme {
    final scheme = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),
      appBarTheme: _buildAppBarTheme(scheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(scheme),

      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withAlpha(51);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      extensions: <ThemeExtension<dynamic>>[
        _AppCardTheme(surfaceColor: _cardColor(AppColors.surfaceDark)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AppCardTheme — custom ThemeExtension carrying card surface colour.
// This avoids the CardTheme / CardThemeData version-mismatch entirely.
// ---------------------------------------------------------------------------

/// Custom [ThemeExtension] that carries the card surface colour.
///
/// Widgets that previously read `theme.cardTheme.color` should instead read:
/// ```dart
/// Theme.of(context).extension<_AppCardTheme>()?.surfaceColor
///   ?? Theme.of(context).colorScheme.surface
/// ```
///
/// In Module 2 all card backgrounds are set inline via [Container.decoration],
/// so this extension acts purely as a typed colour token for future use.
class _AppCardTheme extends ThemeExtension<_AppCardTheme> {
  const _AppCardTheme({required this.surfaceColor});

  /// The background colour used for card surfaces.
  final Color surfaceColor;

  @override
  _AppCardTheme copyWith({Color? surfaceColor}) {
    return _AppCardTheme(surfaceColor: surfaceColor ?? this.surfaceColor);
  }

  @override
  _AppCardTheme lerp(ThemeExtension<_AppCardTheme>? other, double t) {
    if (other is! _AppCardTheme) return this;
    return _AppCardTheme(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
    );
  }
}
