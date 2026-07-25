// ---------------------------------------------------------------------------
// camera_service.dart
// Module 3 — Camera Service for VisionMate AI.
//
// Encapsulates the entire lifecycle of the device camera, providing a clean
// API to the UI layer without exposing CameraController internals.
//
// Responsibilities:
//   • Discover available cameras (front / back).
//   • Initialize the preferred camera (back by default).
//   • Switch between front and back cameras.
//   • Toggle the flash / torch.
//   • Pause and resume the preview (app lifecycle management).
//   • Dispose the camera controller to prevent memory leaks.
//
// This class is intentionally free of any Flutter widget references so it can
// be unit-tested independently.
// ---------------------------------------------------------------------------

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// CameraServiceState — operational state of [CameraService].
// ---------------------------------------------------------------------------

/// Describes the current lifecycle state of [CameraService].
enum CameraServiceState {
  /// The service has not been initialised yet.
  uninitialized,

  /// Cameras are being discovered and the controller is starting.
  initializing,

  /// The camera preview is active and ready for display.
  ready,

  /// The preview is paused (e.g. app moved to background).
  paused,

  /// An unrecoverable error has occurred. See [CameraService.errorMessage].
  error,
}

// ---------------------------------------------------------------------------
// CameraService — pure service class (no ChangeNotifier).
// ---------------------------------------------------------------------------

/// Manages the camera lifecycle for VisionMate AI.
///
/// The owning [State] object is responsible for calling [dispose] when the
/// camera screen is removed from the widget tree to release hardware resources.
///
/// ### Typical usage
/// ```dart
/// final _camera = CameraService();
///
/// @override
/// void initState() {
///   super.initState();
///   _initCamera();
/// }
///
/// Future<void> _initCamera() async {
///   final ok = await _camera.initialize();
///   if (mounted) setState(() {});
/// }
///
/// @override
/// void dispose() {
///   _camera.dispose();
///   super.dispose();
/// }
/// ```
class CameraService {
  // ── Private State ─────────────────────────────────────────────────────────

  /// The active camera controller. Null before init or after disposal.
  CameraController? _controller;

  /// All cameras found on the device.
  List<CameraDescription> _cameras = [];

  /// Index of the currently active camera in [_cameras].
  int _currentIndex = 0;

  /// Whether [dispose] has been called on this service.
  bool _isDisposed = false;

  // ── Public State ──────────────────────────────────────────────────────────

  /// Current operational state.
  CameraServiceState state = CameraServiceState.uninitialized;

  /// Description of the last error, or empty string when no error.
  String errorMessage = '';

  // ── Public Getters ────────────────────────────────────────────────────────

  /// The active [CameraController].
  ///
  /// Only valid when [state] is [CameraServiceState.ready] or
  /// [CameraServiceState.paused].
  CameraController? get controller => _controller;

  /// `true` when the preview is running and ready for display.
  bool get isReady => state == CameraServiceState.ready;

  /// `true` while the service is starting up.
  bool get isInitializing => state == CameraServiceState.initializing;

  /// `true` when the device has more than one camera (switching is possible).
  bool get hasMultipleCameras => _cameras.length > 1;

  /// `true` when the torch / flash is currently active.
  bool get isTorchOn => _controller?.value.flashMode == FlashMode.torch;

  /// The lens direction of the currently active camera.
  CameraLensDirection get currentLensDirection => _cameras.isNotEmpty
      ? _cameras[_currentIndex].lensDirection
      : CameraLensDirection.back;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Discovers available cameras and opens the back camera.
  ///
  /// Returns `true` on success and `false` on failure.
  /// Check [errorMessage] for details when returning `false`.
  Future<bool> initialize() async {
    if (_isDisposed) return false;

    state = CameraServiceState.initializing;
    errorMessage = '';

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        return _setError('No cameras found on this device.');
      }

      // Prefer the back-facing camera as the default.
      final backIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _currentIndex = backIdx != -1 ? backIdx : 0;

      return await _startController(_cameras[_currentIndex]);
    } on CameraException catch (e) {
      return _setError(e.description ?? e.code);
    } catch (e) {
      return _setError(e.toString());
    }
  }

  /// Creates and initialises a [CameraController] for the given [camera].
  ///
  /// Disposes the previous controller before starting a new one.
  Future<bool> _startController(CameraDescription camera) async {
    if (_isDisposed) return false;

    // Release any existing controller first to avoid resource leaks.
    await _releaseController();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      // Audio is not needed for visual navigation assistance.
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();

      // Guard against disposal during the async initialisation gap.
      if (_isDisposed) {
        await controller.dispose();
        return false;
      }

      _controller = controller;
      state = CameraServiceState.ready;
      errorMessage = '';
      return true;
    } on CameraException catch (e) {
      await controller.dispose();
      return _setError(e.description ?? e.code);
    }
  }

  // ── Camera Controls ───────────────────────────────────────────────────────

  /// Switches to the next available camera (front ↔ back).
  ///
  /// No-op if the device has only one camera.
  /// Returns `true` when the new camera is ready.
  Future<bool> switchCamera() async {
    if (_isDisposed || !hasMultipleCameras) return false;

    await stopImageStream();
    state = CameraServiceState.initializing;
    _currentIndex = (_currentIndex + 1) % _cameras.length;
    return await _startController(_cameras[_currentIndex]);
  }

  /// Starts streaming preview frames to the supplied callback.
  ///
  /// Frame delivery is only available when the preview is ready.
  Future<void> startImageStream(
    void Function(CameraImage frame) onAvailable,
  ) async {
    if (_isDisposed || !isReady || _controller == null) return;

    try {
      await _controller!.startImageStream(onAvailable);
    } on CameraException catch (e) {
      debugPrint('[CameraService] startImageStream: ${e.description}');
    }
  }

  /// Stops the active preview image stream.
  Future<void> stopImageStream() async {
    if (_isDisposed || _controller == null) return;

    try {
      await _controller!.stopImageStream();
    } on CameraException catch (e) {
      debugPrint('[CameraService] stopImageStream: ${e.description}');
    }
  }

  /// Toggles the flash between torch-on and off.
  ///
  /// Silently logs and ignores any [CameraException] (e.g. front camera).
  Future<void> toggleFlash() async {
    if (_isDisposed || !isReady || _controller == null) return;
    try {
      final newMode = isTorchOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
    } on CameraException catch (e) {
      // Flash may not be supported on the front camera — not a fatal error.
      debugPrint('[CameraService] toggleFlash: ${e.description}');
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Pauses the camera preview.
  ///
  /// Should be called from [WidgetsBindingObserver.didChangeAppLifecycleState]
  /// when the state transitions to [AppLifecycleState.paused] or
  /// [AppLifecycleState.inactive].
  Future<void> pause() async {
    if (_isDisposed) return;
    if (_controller == null || !(_controller!.value.isInitialized)) return;
    if (state == CameraServiceState.paused) return;

    await stopImageStream();

    try {
      await _controller!.pausePreview();
      state = CameraServiceState.paused;
    } on CameraException catch (e) {
      debugPrint('[CameraService] pause: ${e.description}');
    }
  }

  /// Resumes the camera preview after a [pause].
  ///
  /// Should be called when the state transitions to [AppLifecycleState.resumed].
  Future<void> resume() async {
    if (_isDisposed) return;
    if (_controller == null || !(_controller!.value.isInitialized)) return;
    if (state != CameraServiceState.paused) return;

    try {
      await _controller!.resumePreview();
      state = CameraServiceState.ready;
    } on CameraException catch (e) {
      debugPrint('[CameraService] resume: ${e.description}');
    }
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  /// Releases the camera controller hardware resources.
  ///
  /// After this call the service is inert and should not be reused.
  Future<void> dispose() async {
    _isDisposed = true;
    await stopImageStream();
    await _releaseController();
    state = CameraServiceState.uninitialized;
  }

  /// Disposes the current controller without marking the service as disposed.
  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    try {
      await controller?.dispose();
    } catch (e) {
      debugPrint('[CameraService] _releaseController: $e');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Sets the error state and returns `false` for use in early-return guards.
  bool _setError(String message) {
    state = CameraServiceState.error;
    errorMessage = message;
    return false;
  }
}
