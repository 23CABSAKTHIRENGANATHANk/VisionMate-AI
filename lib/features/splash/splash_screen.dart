// ---------------------------------------------------------------------------
// splash_screen.dart
// Animated splash screen shown on app startup.
// Displays the VisionMate AI logo, name, and tagline with layered animations
// before automatically routing to the Home screen after a brief delay.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// The application entry screen shown for [AppConstants.splashDuration].
///
/// Features:
/// - Animated gradient background (blue → teal).
/// - Logo container with a scale + fade entrance followed by a pulse.
/// - App name fades in after the logo settles.
/// - Tagline slides up into view.
/// - Automatically navigates to [AppConstants.routeHome] on completion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controls the pulsing glow animation on the logo container.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation for the logo glow ring.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Navigate to Home after the splash duration elapses.
    Future.delayed(AppConstants.splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        // Full-screen gradient background.
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Logo Section ─────────────────────────────────────────────

              // Outer glow ring — scales with the pulse animation.
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(20),
                      ),
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut),

              const SizedBox(height: 0),

              // Logo container — overlaps the glow ring via a Stack.
              Stack(
                alignment: Alignment.center,
                children: [
                  // Invisible spacer to reserve glow ring height.
                  const SizedBox(height: 148, width: 148),

                  // Main logo container.
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.0, 1.0),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 500.ms),
                ],
              ),

              const SizedBox(height: 40),

              // ── App Name ─────────────────────────────────────────────────

              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0.0,
                    delay: 500.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 12),

              // ── Tagline ───────────────────────────────────────────────────

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppConstants.splashTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.4,
                    end: 0.0,
                    delay: 800.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),

              const Spacer(flex: 2),

              // ── Loading Indicator ─────────────────────────────────────────

              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withAlpha(178),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
