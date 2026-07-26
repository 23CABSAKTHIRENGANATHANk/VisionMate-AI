// ---------------------------------------------------------------------------
// camera_controls_bar.dart
// Module 3 — Bottom camera controls bar for VisionMate AI.
//
// Contains three action buttons arranged horizontally:
//   • Flash toggle  (left)   — toggles torch on/off.
//   • Capture       (centre) — placeholder; shows a SnackBar.
//   • Switch camera (right)  — swaps front ↔ back camera.
//
// All buttons include Semantics labels for TalkBack / VoiceOver accessibility.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_strings.dart';

/// The bottom control bar displayed over the live camera preview.
///
/// Provides flash toggle, a placeholder capture button, and camera switching.
class CameraControlsBar extends StatelessWidget {
  const CameraControlsBar({
    super.key,
    required this.isTorchOn,
    required this.hasMultipleCameras,
    required this.isSwitching,
    required this.onFlashToggle,
    required this.onCapture,
    required this.onSwitchCamera,
    this.onBlackoutToggle,
    this.isBlackoutMode = false,
  });

  /// Whether the torch is currently active.
  final bool isTorchOn;

  /// Whether camera switching is available.
  final bool hasMultipleCameras;

  /// Whether a camera switch is in progress (disables the switch button).
  final bool isSwitching;

  /// Invoked when the user taps the flash button.
  final VoidCallback onFlashToggle;

  /// Invoked when the user taps the capture button.
  final VoidCallback onCapture;

  /// Invoked when the user taps the switch-camera button.
  final VoidCallback onSwitchCamera;

  /// Invoked when the user toggles battery saver blackout mode.
  final VoidCallback? onBlackoutToggle;

  /// Whether screen blackout mode is currently active.
  final bool isBlackoutMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        // Semi-transparent gradient rising from the bottom.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(204),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Flash toggle ─────────────────────────────────────────────────
            _ControlButton(
              key: const Key('camera_flash_button'),
              semanticLabel: isTorchOn
                  ? AppStrings.cameraFlashOff
                  : AppStrings.cameraFlashOn,
              icon: isTorchOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              iconColor: isTorchOn ? Colors.amber : Colors.white,
              onTap: onFlashToggle,
            ).animate(key: ValueKey(isTorchOn)).fadeIn(duration: 200.ms),

            // ── Battery Saver Blackout Mode ───────────────────────────────
            if (onBlackoutToggle != null)
              _ControlButton(
                key: const Key('camera_blackout_button'),
                semanticLabel: isBlackoutMode
                    ? 'Exit Battery Saver'
                    : 'Battery Saver Blackout',
                icon: isBlackoutMode
                    ? Icons.visibility_rounded
                    : Icons.nightlight_round,
                iconColor: isBlackoutMode ? Colors.cyanAccent : Colors.white,
                onTap: onBlackoutToggle!,
              ),

            // ── Capture button (centre, larger) ──────────────────────────────
            _CaptureButton(
              key: const Key('camera_capture_button'),
              onTap: onCapture,
            ),

            // ── Switch camera ────────────────────────────────────────────────
            if (hasMultipleCameras)
              _ControlButton(
                key: const Key('camera_switch_button'),
                semanticLabel: AppStrings.cameraSwitchCamera,
                icon: Icons.flip_camera_ios_rounded,
                iconColor: Colors.white,
                onTap: isSwitching ? null : onSwitchCamera,
              )
            else
              // Invisible placeholder to keep layout symmetrical.
              const SizedBox(width: 56, height: 56),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// _ControlButton — circular icon button for flash and switch-camera.
// ---------------------------------------------------------------------------

/// A circular frosted-glass icon button used in [CameraControlsBar].
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final String semanticLabel;
  final IconData icon;
  final Color iconColor;

  /// Null when the button should be disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap != null ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(77),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CaptureButton — large shutter button in the centre of the controls bar.
// ---------------------------------------------------------------------------

/// The shutter / capture button.
///
/// In Module 3, tapping this is a placeholder — the parent shows a SnackBar.
/// Module 4 will implement actual image capture here.
class _CaptureButton extends StatefulWidget {
  const _CaptureButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(TapDownDetails _) async {
    await _controller.forward();
  }

  Future<void> _onTapUp(TapUpDetails _) async {
    await _controller.reverse();
    widget.onTap();
  }

  Future<void> _onTapCancel() async {
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.cameraCaptureButton,
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
