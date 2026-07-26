// ---------------------------------------------------------------------------
// camera_screen.dart
// Module 3 — Main Camera Screen for VisionMate AI.
//
// Responsibilities:
//   • Manages runtime camera permission checks via permission_handler.
//   • Renders [CameraPermissionScreen] when permission is denied.
//   • Controls [CameraService] lifecycle with [WidgetsBindingObserver].
//   • Pauses preview on app pause/background, resumes on foreground.
//   • Displays full-screen camera preview with overlay controls, viewfinder,
//     and top status bar.
//   • Fully accessible with Material 3 styling and zero memory leaks.
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../../models/tracked_object.dart';
import '../../services/vision_navigation_engine.dart';

import '../../core/constants/app_strings.dart';
import '../../services/camera_service.dart';
import '../../services/navigation_pipeline_processor.dart';
import '../../services/obstacle_priority_analyzer.dart';
import '../../services/object_detection_service.dart';
import '../../services/object_detector_service.dart';
import '../../services/yolo_detector_service.dart'
    hide DetectionFrame, DetectionPlane, ConvertParams;
import '../../models/navigation_data.dart';
import '../detection/detection_result.dart';
import '../voice/voice_service.dart';
import '../../core/debug_settings.dart';
import 'camera_permission_screen.dart';
import 'widgets/camera_controls_bar.dart';
import 'widgets/camera_top_bar.dart';
import 'widgets/camera_viewfinder_overlay.dart';
import 'widgets/detection_overlay.dart';

/// Phase states for the camera screen workflow.
enum _CameraPhase {
  checkingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  error,
}

/// The main interactive Camera Screen.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ObjectDetectionService _detectionService =
      ObjectDetectionService.instance;

  final NavigationPipelineProcessor _pipelineProcessor =
      NavigationPipelineProcessor.instance;

  static const Duration _frameProcessingInterval = Duration(milliseconds: 30);

  _CameraPhase _phase = _CameraPhase.checkingPermission;
  bool _isBlackoutMode = false;
  bool _isSwitching = false;
  bool _isDetectionInitializing = true;
  bool _isStartingDetectionStream = false;
  String? _detectionError;

  double _avgDetectLatencyMs = 0.0;
  int _detectLatencyCount = 0;

  List<DetectionResult> _detections = const <DetectionResult>[];

  /// Dynamically tracked & smoothed 80+ COCO objects from VisionNavigationEngine.
  List<TrackedObject> _trackedObjects = const <TrackedObject>[];

  /// Live Google ML Kit detected and tracked objects.
  final List<DetectedObject> _mlKitObjects = const <DetectedObject>[];
  final Size _mlKitImageSize = Size.zero;

  /// Pre-computed obstacles from the pipeline — passed directly to DetectionOverlay
  /// so the full pipeline is NOT run inside build() on every frame.
  List<ProcessedObstacle> _processedObstacles = const <ProcessedObstacle>[];

  /// Rate-limit timestamp: last time _onCameraImageAvailable passed a frame.
  DateTime _lastFrameProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Runtime metrics for debug overlay
  int _framesThisSecond = 0;
  DateTime _fpsWindowStart = DateTime.now();
  int _lastFps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start camera permission and preview init immediately.
    unawaited(_checkPermissionAndInitialize());

    // Load the detection model in the background so the camera can appear faster.
    unawaited(_loadDetectionModel());
    // Ensure TTS is initialized early to avoid first-speech latency.
    unawaited(VoiceService.instance.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(VoiceService.instance.stop());
    unawaited(_cameraService.dispose());
    _detectionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraService.controller;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      debugPrint(
        '[CameraScreen] App paused or inactive, stopping stream and speech.',
      );
      _cameraService.pause().then((_) {
        unawaited(VoiceService.instance.stop());
        if (mounted) setState(() {});
      });
      return;
    }

    if (state == AppLifecycleState.resumed) {
      debugPrint('[CameraScreen] App resumed, restoring camera state.');
      if (_phase == _CameraPhase.permissionDenied ||
          _phase == _CameraPhase.permissionPermanentlyDenied) {
        unawaited(_checkPermissionAndInitialize());
        return;
      }

      if (controller == null || !controller.value.isInitialized) {
        return;
      }

      // Clear stale tracks accumulated during the background pause so that
      // objects from before the pause do not reappear as ghost detections.
      _pipelineProcessor.reset();

      _cameraService.resume().then((_) async {
        if (_detectionService.isLoaded && _cameraService.isReady) {
          await _startDetectionStream();
        }
        if (mounted) setState(() {});
      });
    }
  }

  // ── Permission & Initialization Workflow ─────────────────────────────────

  Future<void> _checkPermissionAndInitialize() async {
    if (!mounted) return;
    setState(() => _phase = _CameraPhase.checkingPermission);

    final status = await Permission.camera.status;
    if (!mounted) return;

    if (status.isGranted) {
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() => _phase = _CameraPhase.permissionPermanentlyDenied);
    } else {
      // First time or soft-denied: request permission directly.
      final result = await Permission.camera.request();
      if (!mounted) return;

      if (result.isGranted) {
        await _initializeCamera();
      } else if (result.isPermanentlyDenied) {
        setState(() => _phase = _CameraPhase.permissionPermanentlyDenied);
      } else {
        setState(() => _phase = _CameraPhase.permissionDenied);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() => _phase = _CameraPhase.initializing);

    final cameraReady = await _cameraService.initialize();
    if (!mounted) return;

    if (cameraReady) {
      setState(() => _phase = _CameraPhase.ready);
      await _startDetectionStream();
    } else {
      setState(() => _phase = _CameraPhase.error);
    }
  }

  Future<void> _loadDetectionModel() async {
    if (_detectionService.isLoaded) {
      if (mounted) {
        setState(() {
          _isDetectionInitializing = false;
          _detectionError = null;
        });
      }
      return;
    }
    setState(() => _isDetectionInitializing = true);

    try {
      VisionNavigationEngine.instance.initialize();
      unawaited(YoloDetectorService.instance.initialize());
      ObjectDetectorService.instance.initialize();
      await _detectionService.initialize();
      if (!mounted) return;

      if (_cameraService.isReady) {
        await _startDetectionStream();
      }

      setState(() {
        _isDetectionInitializing = false;
        _detectionError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDetectionInitializing = false;
          _detectionError =
              _detectionService.lastError ?? 'AI model unavailable';
        });
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handleSwitchCamera() async {
    if (_isSwitching) return;
    setState(() => _isSwitching = true);

    // Reset tracker state before starting a new camera session to avoid
    // ghost tracks from the previous camera contaminating the new view.
    _pipelineProcessor.reset();

    final success = await _cameraService.switchCamera();
    if (success) {
      await _startDetectionStream();
    }

    if (mounted) {
      setState(() => _isSwitching = false);
    }
  }

  Future<void> _handleToggleFlash() async {
    await _cameraService.toggleFlash();
    if (mounted) setState(() {});
  }

  void _handleCapturePlaceholder() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.cameraCaptureSnackbar),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _startDetectionStream() async {
    if (_isStartingDetectionStream) return;
    if (!_detectionService.isLoaded || !_cameraService.isReady) return;

    _isStartingDetectionStream = true;
    try {
      if (kDebugMode) {
        debugPrint('[CameraScreen] Starting detection stream...');
      }
      await _cameraService.stopImageStream();
      await _cameraService.startImageStream(_onCameraImageAvailable);
      if (kDebugMode) {
        debugPrint('[CameraScreen] Detection stream started.');
      }
    } finally {
      _isStartingDetectionStream = false;
    }
  }

  void _onCameraImageAvailable(CameraImage image) {
    if (!_detectionService.isLoaded) {
      if (kDebugMode) {
        debugPrint('[CameraScreen] Skipping frame: model not loaded');
      }
      return;
    }
    if (_detectionService.isProcessing) {
      if (kDebugMode) {
        debugPrint('[CameraScreen] Skipping frame: detection busy');
      }
      return;
    }

    final now = DateTime.now();
    // Update simple FPS counter (debug only).
    if (now.difference(_fpsWindowStart) >= const Duration(seconds: 1)) {
      _lastFps = _framesThisSecond;
      _framesThisSecond = 0;
      _fpsWindowStart = now;
      if (kDebugMode && mounted) setState(() {});
    }
    _framesThisSecond++;
    if (now.difference(_lastFrameProcessedAt) < _frameProcessingInterval) {
      if (kDebugMode) {
        debugPrint('[CameraScreen] Skipping frame: rate limited');
      }
      return;
    }

    _lastFrameProcessedAt = now;

    final sensorOrientation =
        _cameraService.controller?.description.sensorOrientation ?? 90;
    final deviceOrientation =
        _cameraService.controller?.value.deviceOrientation ??
            DeviceOrientation.portraitUp;

    // 1. Unified 60 FPS Vision Navigation Engine (80+ COCO classes + Pinhole Distance + EMA Smoothing)
    unawaited(
      VisionNavigationEngine.instance
          .processFrame(
        image: image,
        sensorOrientation: sensorOrientation,
        deviceOrientation: deviceOrientation,
      )
          .then((result) {
        if (!mounted) return;
        setState(() {
          _trackedObjects = result.trackedObjects;
        });

        if (result.speechPrompt != null) {
          unawaited(VoiceService.instance.speak(result.speechPrompt!));
        }
      }),
    );

    // 2. YOLO TFLite Object Category Classifier
    unawaited(
      YoloDetectorService.instance.detect(image).then((detections) {
        if (!mounted) return;
        if (detections.isNotEmpty) {
          setState(() {
            _detections = detections;
          });

          final navData = _pipelineProcessor.process(detections);
          _processedObstacles = navData.obstacles;

          if (navData.shouldSpeak) {
            unawaited(VoiceService.instance.speak(navData.voiceGuidanceText));
          }
        }
      }),
    );
  }



  // ── Build Methods ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _CameraPhase.checkingPermission:
      case _CameraPhase.initializing:
        return _buildLoadingScreen();

      case _CameraPhase.permissionDenied:
        return CameraPermissionScreen(
          isPermanentlyDenied: false,
          onPermissionGranted: _initializeCamera,
        );

      case _CameraPhase.permissionPermanentlyDenied:
        return CameraPermissionScreen(
          isPermanentlyDenied: true,
          onPermissionGranted: _initializeCamera,
        );

      case _CameraPhase.error:
        return _buildErrorScreen();

      case _CameraPhase.ready:
        return _buildLiveCameraView();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              AppStrings.cameraStatusInitializing,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.cameraErrorTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraService.errorMessage.isNotEmpty
                    ? _cameraService.errorMessage
                    : 'Failed to access camera hardware.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.cameraErrorRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCameraView() {
    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full Screen Live Preview ───────────────────────────────────────
          Center(child: CameraPreview(controller)),

          // ── Live bounding boxes: pre-computed obstacles, not raw detections ─
          // FIX (MED-1): Pass _processedObstacles to avoid pipeline in build().
          DetectionOverlay(
            trackedObjects: _trackedObjects,
            mlKitObjects: _mlKitObjects,
            imageSize: _mlKitImageSize,
            rotation: InputImageRotation.rotation90deg,
            obstacles: _processedObstacles,
            detections: _detections,
          ),

          // ── Real-Time Live Detection Metrics Banner ───────────────────
          Positioned(
            top: 56,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF34C759), width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vision Engine Live: ${_trackedObjects.length} object(s)',
                    style: const TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'FPS: $_lastFps | Latency: ${_avgDetectLatencyMs.toStringAsFixed(0)}ms',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Viewfinder Corner Brackets Overlay ─────────────────────────────
          const CameraViewfinderOverlay(),

          // ── Top Bar (Back & Status) ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraTopBar(
              state: _cameraService.state,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          if (_isDetectionInitializing || _detectionError != null)
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.68),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _detectionError != null
                        ? Colors.redAccent
                        : Colors.white70,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _detectionError ?? AppStrings.cameraDetectionLoading,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _detectionError != null
                        ? Colors.redAccent
                        : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ── Battery Saver Blackout Mode Overlay ─────────────────────────
          if (_isBlackoutMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isBlackoutMode = false),
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.nightlight_round,
                        color: Colors.cyanAccent,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Battery Saver Mode Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI scanning & voice guidance remain active.\nTap anywhere to wake preview.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Controls Bar ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CameraControlsBar(
              isTorchOn: _cameraService.isTorchOn,
              hasMultipleCameras: _cameraService.hasMultipleCameras,
              isSwitching: _isSwitching,
              onFlashToggle: _handleToggleFlash,
              onCapture: _handleCapturePlaceholder,
              onSwitchCamera: _handleSwitchCamera,
              onBlackoutToggle: () =>
                  setState(() => _isBlackoutMode = !_isBlackoutMode),
              isBlackoutMode: _isBlackoutMode,
            ),
          ),
          // ── Debug Metrics Overlay (toggleable via Settings) ────────────
          if (kDebugMode)
            ValueListenableBuilder<bool>(
              valueListenable: DebugSettings.showDebugOverlay,
              builder: (context, show, _) {
                if (!show) return const SizedBox.shrink();
                return Positioned(
                  top: 56,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FPS: $_lastFps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detect: ${_avgDetectLatencyMs.toStringAsFixed(1)} ms',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DetCount: $_detectLatencyCount',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
