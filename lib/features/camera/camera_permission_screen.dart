// ---------------------------------------------------------------------------
// camera_permission_screen.dart
// Module 3 — Camera Permission Request Screen for VisionMate AI.
//
// Shown when the camera permission has not been granted.
// Two modes are supported:
//   1. [isPermanentlyDenied] = false → shows "Grant Camera Permission" button
//      which calls Permission.camera.request().
//   2. [isPermanentlyDenied] = true  → shows "Open App Settings" button which
//      calls openAppSettings() so the user can manually enable the permission.
//
// The parent (CameraScreen) provides the [onPermissionGranted] callback which
// is invoked when the permission is successfully obtained.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Displayed when the camera permission has been denied.
///
/// Parameters:
/// - [isPermanentlyDenied]: when `true`, the "Open Settings" button is shown
///   instead of the standard "Grant" button.
/// - [onPermissionGranted]: callback invoked after permission is successfully
///   granted, signalling the parent to re-initialise the camera.
class CameraPermissionScreen extends StatefulWidget {
  const CameraPermissionScreen({
    super.key,
    required this.onPermissionGranted,
    this.isPermanentlyDenied = false,
  });

  /// Called when the user successfully grants the camera permission.
  final VoidCallback onPermissionGranted;

  /// Whether the permission was permanently denied (requires settings redirect).
  final bool isPermanentlyDenied;

  @override
  State<CameraPermissionScreen> createState() => _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends State<CameraPermissionScreen> {
  /// Tracks whether a permission request is in flight.
  bool _isRequesting = false;

  // ── Permission Request ────────────────────────────────────────────────────

  /// Requests camera permission and invokes [onPermissionGranted] if granted.
  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (status.isGranted) {
        widget.onPermissionGranted();
      }
      // If still denied, the parent will rebuild this screen with the latest
      // denied state on the next navigation cycle.
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  /// Opens device app settings so the user can manually grant the permission.
  Future<void> _openSettings() async {
    setState(() => _isRequesting = true);
    try {
      await openAppSettings();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      // Gradient background consistent with the app's brand.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width > 600 ? 80 : 32,
              vertical: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Camera Icon ──────────────────────────────────────────────
                _AnimatedCameraIcon(
                  isDenied: widget.isPermanentlyDenied,
                ),

                const SizedBox(height: 40),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  widget.isPermanentlyDenied
                      ? AppStrings.cameraPermissionDeniedTitle
                      : AppStrings.cameraPermissionTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, delay: 400.ms),

                const SizedBox(height: 16),

                // ── Body ─────────────────────────────────────────────────────
                Text(
                  widget.isPermanentlyDenied
                      ? AppStrings.cameraPermissionDeniedBody
                      : AppStrings.cameraPermissionBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204),
                    height: 1.6,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // ── Primary CTA ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isRequesting
                        ? null
                        : (widget.isPermanentlyDenied
                            ? _openSettings
                            : _requestPermission),
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            widget.isPermanentlyDenied
                                ? Icons.settings_rounded
                                : Icons.camera_alt_rounded,
                          ),
                    label: Text(
                      widget.isPermanentlyDenied
                          ? AppStrings.cameraPermissionSettingsButton
                          : AppStrings.cameraPermissionGrantButton,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      elevation: 0,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      delay: 700.ms,
                    ),

                // ── Back button ───────────────────────────────────────────────
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 14,
                    ),
                  ),
                ).animate().fadeIn(delay: 850.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedCameraIcon — pulsing gradient icon displayed on the permission screen.
// ---------------------------------------------------------------------------

/// An animated camera icon with a soft pulsing glow, conveying the purpose
/// of the permission request clearly and visually.
class _AnimatedCameraIcon extends StatefulWidget {
  const _AnimatedCameraIcon({required this.isDenied});

  /// When `true`, shows a crossed-out / blocked camera icon.
  final bool isDenied;

  @override
  State<_AnimatedCameraIcon> createState() => _AnimatedCameraIconState();
}

class _AnimatedCameraIconState extends State<_AnimatedCameraIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha(77),
            width: 2,
          ),
        ),
        child: Icon(
          widget.isDenied
              ? Icons.no_photography_rounded
              : Icons.camera_alt_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }
}
