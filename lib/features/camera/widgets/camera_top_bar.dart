// ---------------------------------------------------------------------------
// camera_top_bar.dart
// Module 3 — Top navigation and status bar overlay for VisionMate AI camera.
//
// Features:
//   • Back button with tooltip and semantic accessibility label.
//   • Status indicator chip displaying LIVE, PAUSED, INITIALIZING, or ERROR.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_strings.dart';
import '../../../services/camera_service.dart';

/// The top overlay bar displayed over the live camera preview.
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.state,
    required this.onBack,
  });

  /// The current state of the [CameraService].
  final CameraServiceState state;

  /// Callback when back arrow is pressed.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(160),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Back Button ──────────────────────────────────────────────────
            Semantics(
              label: 'Back',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                tooltip: 'Back',
                onPressed: onBack,
              ),
            ),

            // ── Status Chip ──────────────────────────────────────────────────
            _StatusChip(state: state),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ---------------------------------------------------------------------------
// _StatusChip — status badge for camera state.
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final CameraServiceState state;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final IconData icon;

    switch (state) {
      case CameraServiceState.ready:
        label = AppStrings.cameraStatusLive;
        color = const Color(0xFF4CAF50);
        icon = Icons.fiber_manual_record_rounded;
        break;
      case CameraServiceState.paused:
        label = AppStrings.cameraStatusPaused;
        color = const Color(0xFFFFC107);
        icon = Icons.pause_circle_filled_rounded;
        break;
      case CameraServiceState.initializing:
      case CameraServiceState.uninitialized:
        label = AppStrings.cameraStatusInitializing;
        color = const Color(0xFF2196F3);
        icon = Icons.sync_rounded;
        break;
      case CameraServiceState.error:
        label = AppStrings.cameraStatusError;
        color = const Color(0xFFF44336);
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(150),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
