// ---------------------------------------------------------------------------
// app_colors.dart
// Centralised color palette for VisionMate AI.
// All colours used across the app are defined here to guarantee visual
// consistency and to simplify future theme changes.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Immutable color definitions for the VisionMate AI design system.
///
/// Palette: soft blue → teal gradient family, with semantic accent colours
/// for statuses and carefully chosen dark-mode equivalents.
class AppColors {
  // Private constructor — pure-static utility class.
  AppColors._();

  // ── Primary Brand Palette ─────────────────────────────────────────────────

  /// Primary brand blue — used as the seed for the Material 3 colour scheme.
  static const Color primary = Color(0xFF1A73E8);

  /// Lighter shade of the primary blue, used for secondary highlights.
  static const Color primaryLight = Color(0xFF4FC3F7);

  /// Teal accent colour that forms the second stop of gradient backgrounds.
  static const Color teal = Color(0xFF00ACC1);

  /// Lighter teal used as a gradient terminal colour on cards and headers.
  static const Color tealLight = Color(0xFF4DD0E1);

  // ── Gradient Definitions ──────────────────────────────────────────────────

  /// Deep ocean gradient — used for the Splash screen background.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF006064)],
  );

  /// Soft sky gradient — used for the Home screen header banner.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0097A7)],
  );

  // ── Feature Card Gradients ─────────────────────────────────────────────────

  /// Gradient for the "Start Navigation" feature card (indigo → blue).
  static const LinearGradient navCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
  );

  /// Gradient for the "Camera Preview" feature card (cyan → teal).
  static const LinearGradient cameraCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0097A7), Color(0xFF00695C)],
  );

  /// Gradient for the "Settings" feature card (purple → indigo).
  static const LinearGradient settingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B1FA2), Color(0xFF3949AB)],
  );

  /// Gradient for the "Help" feature card (deep teal → green).
  static const LinearGradient helpCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00695C), Color(0xFF1B5E20)],
  );

  // ── Status Colours ────────────────────────────────────────────────────────

  /// Colour for a "Ready / OK" status indicator dot.
  static const Color statusReady = Color(0xFF43A047);

  /// Colour for a "Warning / Not Loaded" status indicator dot.
  static const Color statusWarning = Color(0xFFFB8C00);

  /// Colour for an "Error / Unavailable" status indicator dot.
  static const Color statusError = Color(0xFFE53935);

  // ── Neutral Surface Colours ───────────────────────────────────────────────

  /// Light mode scaffold background — near-white cool grey.
  static const Color backgroundLight = Color(0xFFF0F4FF);

  /// Dark mode scaffold background — deep navy.
  static const Color backgroundDark = Color(0xFF0D1117);

  /// Light mode card surface colour.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Dark mode card surface colour.
  static const Color surfaceDark = Color(0xFF161B22);

  /// Subtle divider / border colour in light mode.
  static const Color dividerLight = Color(0xFFE2E8F0);

  /// Subtle divider / border colour in dark mode.
  static const Color dividerDark = Color(0xFF30363D);

  // ── Text Colours ──────────────────────────────────────────────────────────

  /// Primary text colour in light mode.
  static const Color textPrimaryLight = Color(0xFF0F172A);

  /// Secondary / muted text colour in light mode.
  static const Color textSecondaryLight = Color(0xFF64748B);

  /// Primary text colour in dark mode.
  static const Color textPrimaryDark = Color(0xFFE2E8F0);

  /// Secondary / muted text colour in dark mode.
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ── Camera Screen ─────────────────────────────────────────────────────────

  /// Border colour for the camera viewfinder frame illustration.
  static const Color cameraFrameColor = Color(0xFF00ACC1);

  /// Scanning line colour on the camera placeholder screen.
  static const Color cameraScanLine = Color(0xFF4FC3F7);
}
