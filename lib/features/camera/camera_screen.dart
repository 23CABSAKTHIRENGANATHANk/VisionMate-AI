// ---------------------------------------------------------------------------
// camera_screen.dart
// Placeholder camera screen for VisionMate AI.
// Displays a modern illustrated camera frame with an animated scanning line
// and a "Module 3" coming-soon message. No camera API is used.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';

/// Camera placeholder screen — shown until Module 3 integrates live capture.
///
/// Visual elements:
/// - Gradient AppBar for brand consistency.
/// - Animated camera frame drawn with a [CustomPainter].
/// - Scanning line that sweeps vertically inside the frame (illustrative only).
/// - Coming-soon badge and descriptive text.
/// - Back button returns to the previous screen.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  // Controls the vertical sweep of the illustrative scanning line.
  late final AnimationController _scanController;
  late final Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= AppConstants.tabletBreakpoint;

    // The camera frame fills most of the screen width on phones, capped on
    // tablets for a natural look.
    final frameSize = isTablet
        ? size.width * 0.45
        : size.width * 0.78;

    return Scaffold(
      // Gradient AppBar matching the Home screen header brand.
      appBar: AppBar(
        title: const Text(
          AppStrings.cameraTitle,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet
              ? AppConstants.screenPaddingTablet
              : AppConstants.screenPadding,
          vertical: 32,
        ),
        child: Column(
          children: [
            // ── Camera Frame Illustration ──────────────────────────────────
            SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Camera frame painter (corner brackets + dark background).
                  CustomPaint(
                    size: Size(frameSize, frameSize),
                    painter: _CameraFramePainter(),
                  ),

                  // Animated scanning line sweeps top → bottom.
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, _) {
                      final topOffset = _scanAnimation.value *
                          (frameSize - 32); // stay within frame
                      return Positioned(
                        top: topOffset + 16, // 16 px inner padding
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.cameraScanLine,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Centre icon.
                  Center(
                    child: Icon(
                      Icons.camera_enhance_rounded,
                      size: frameSize * 0.28,
                      color: AppColors.cameraFrameColor.withAlpha(128),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // ── Coming Soon Badge ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upcoming_rounded,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.cameraComingSoon,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms),

            const SizedBox(height: 20),

            // ── Primary Message ────────────────────────────────────────────
            Text(
              AppStrings.cameraPlaceholderTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
                .animate()
                .fadeIn(delay: 550.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0.0, delay: 550.ms, duration: 500.ms),

            const SizedBox(height: 12),

            // ── Supporting Text ────────────────────────────────────────────
            Text(
              AppStrings.cameraPlaceholderBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(178),
                height: 1.6,
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms),

            const SizedBox(height: 40),

            // ── Back Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Home'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CameraFramePainter — draws corner bracket viewfinder decorations.
// ---------------------------------------------------------------------------

/// Custom painter that draws a dark frosted background with teal corner
/// brackets to simulate a camera viewfinder / AR frame.
class _CameraFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Dark background ──────────────────────────────────────────────────

    final bgPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // ── Corner brackets ───────────────────────────────────────────────────

    const bracketLength = 28.0;
    const bracketWidth = 3.5;
    const inset = 16.0;
    const cornerRadius = 4.0;

    final bracketPaint = Paint()
      ..color = AppColors.cameraFrameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left
      [
        Offset(inset + cornerRadius, inset),
        Offset(inset + bracketLength, inset),
        Offset(inset, inset + cornerRadius),
        Offset(inset, inset + bracketLength),
      ],
      // Top-right
      [
        Offset(size.width - inset - cornerRadius, inset),
        Offset(size.width - inset - bracketLength, inset),
        Offset(size.width - inset, inset + cornerRadius),
        Offset(size.width - inset, inset + bracketLength),
      ],
      // Bottom-left
      [
        Offset(inset + cornerRadius, size.height - inset),
        Offset(inset + bracketLength, size.height - inset),
        Offset(inset, size.height - inset - cornerRadius),
        Offset(inset, size.height - inset - bracketLength),
      ],
      // Bottom-right
      [
        Offset(size.width - inset - cornerRadius, size.height - inset),
        Offset(size.width - inset - bracketLength, size.height - inset),
        Offset(size.width - inset, size.height - inset - cornerRadius),
        Offset(size.width - inset, size.height - inset - bracketLength),
      ],
    ];

    for (final corner in corners) {
      // Horizontal bracket line.
      canvas.drawLine(corner[0], corner[1], bracketPaint);
      // Vertical bracket line.
      canvas.drawLine(corner[2], corner[3], bracketPaint);
    }

    // ── Centre crosshair dot ──────────────────────────────────────────────

    final dotPaint = Paint()
      ..color = AppColors.cameraFrameColor.withAlpha(102)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
