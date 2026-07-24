// ---------------------------------------------------------------------------
// status_indicator.dart
// Animated status indicator: a pulsing coloured dot alongside a label.
// Used in the Home screen System Status card to show real-time state.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The operational status of a system component.
enum IndicatorStatus {
  /// Component is ready and operational.
  ready,

  /// Component has a non-critical warning or is not yet loaded.
  warning,

  /// Component has encountered an error or is unavailable.
  error,
}

/// An animated indicator row showing a pulsing dot and a status label.
///
/// The dot colour reflects [status]:
/// - [IndicatorStatus.ready] → green
/// - [IndicatorStatus.warning] → amber
/// - [IndicatorStatus.error] → red
///
/// The dot pulses with a subtle scale animation to signal liveness.
///
/// Example:
/// ```dart
/// StatusIndicator(
///   label: AppConstants.statusCameraReady,
///   status: IndicatorStatus.ready,
/// )
/// ```
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.label,
    required this.status,
  });

  /// The human-readable label displayed beside the indicator dot.
  final String label;

  /// The operational status that determines dot colour and icon.
  final IndicatorStatus status;

  /// Maps [IndicatorStatus] to a display colour.
  Color _resolveColor(BuildContext context) {
    switch (status) {
      case IndicatorStatus.ready:
        return const Color(0xFF43A047); // green
      case IndicatorStatus.warning:
        return const Color(0xFFFB8C00); // amber
      case IndicatorStatus.error:
        return const Color(0xFFE53935); // red
    }
  }

  /// Maps [IndicatorStatus] to a trailing icon.
  IconData _resolveIcon() {
    switch (status) {
      case IndicatorStatus.ready:
        return Icons.check_circle_rounded;
      case IndicatorStatus.warning:
        return Icons.warning_rounded;
      case IndicatorStatus.error:
        return Icons.cancel_rounded;
    }
  }

  /// Maps [IndicatorStatus] to a semantic description for screen readers.
  String _resolveSemanticDescription() {
    switch (status) {
      case IndicatorStatus.ready:
        return '$label: Ready';
      case IndicatorStatus.warning:
        return '$label: Warning';
      case IndicatorStatus.error:
        return '$label: Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(context);
    final icon = _resolveIcon();
    final theme = Theme.of(context);

    return Semantics(
      label: _resolveSemanticDescription(),
      child: Row(
        children: [
          // Pulsing dot — animates with a repeating scale effect.
          _PulsingDot(color: color)
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(width: 10),

          // Status label — expands to fill available horizontal space.
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Trailing status icon.
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PulsingDot — private helper for the animated indicator dot.
// ---------------------------------------------------------------------------

/// A small filled circle used as the animated status dot.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(128),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
