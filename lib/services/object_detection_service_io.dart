import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../features/detection/detection_result.dart';

/// Handles TensorFlow Lite object detection inference on FFI-capable platforms.
class ObjectDetectionService {
  ObjectDetectionService._();

  static final ObjectDetectionService instance = ObjectDetectionService._();

  static const String modelAsset = 'assets/models/ssd_mobilenet.tflite';
  static const String labelsAsset = 'assets/models/ssd_mobilenet_labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = [];

  late final List<List<List<double>>> _outputLocations;
  late final List<List<double>> _outputClasses;
  late final List<List<double>> _outputScores;
  late final List<double> _numDetections;

  bool _isLoaded = false;
  bool _isInitializing = false;
  bool _isProcessing = false;

  /// Image dimensions expected by the model.
  late final int inputWidth;
  late final int inputHeight;
  late final int inputType; // 1=uint8, 4=float32

  /// Minimum detection confidence threshold.
  double confidenceThreshold = 0.50;

  String? lastError;

  bool get isLoaded => _isLoaded;

  bool get isProcessing => _isProcessing;

  /// Loads the model and label file from assets in parallel.
  Future<void> initialize() async {
    if (_isLoaded || _isInitializing) return;

    _isInitializing = true;

    try {
      // Load model and labels in parallel
      final results = await Future.wait<dynamic>([
        Interpreter.fromAsset(modelAsset),
        rootBundle.loadString(labelsAsset),
      ], eagerError: true);

      _interpreter = results[0] as Interpreter;
      final labelData = results[1] as String;

      _labels = labelData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final inputTensor = _interpreter!.getInputTensor(0);
      _outputLocations = List.generate(
        1,
        (_) => List.generate(10, (_) => List.filled(4, 0.0)),
      );
      _outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
      _outputScores = List.generate(1, (_) => List.filled(10, 0.0));
      _numDetections = List.filled(1, 0.0);
      final shape = inputTensor.shape;
      inputHeight = shape[1];
      inputWidth = shape[2];
      // Store type index: 1=uint8, 4=float32
      try {
        final tensorType = inputTensor.type;
        inputType = tensorType.index;
      } catch (_) {
        inputType = 4; // Default to float32
      }

      _isLoaded = true;
      lastError = null;
    } catch (e) {
      lastError = 'AI model failed to load.';
      debugPrint('[ObjectDetectionService] initialize error: $e');
      _isLoaded = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Releases interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    _isProcessing = false;
  }

  /// Runs detection on the provided camera frame.
  Future<List<DetectionResult>> detect(DetectionFrame frame) async {
    if (!_isLoaded || _interpreter == null || _isProcessing) {
      return const <DetectionResult>[];
    }

    _isProcessing = true;
    try {
      final converted = await compute<DetectionFrame, img.Image>(
        _convertDetectionFrame,
        frame,
      );

      final resized = img.copyResize(
        converted,
        width: inputWidth,
        height: inputHeight,
        interpolation: img.Interpolation.linear,
      );

      final input = _createInputTensor(resized);

      final outputs = <int, Object>{
        0: _outputLocations,
        1: _outputClasses,
        2: _outputScores,
        3: _numDetections,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      return _postProcessDetections(
        _outputLocations,
        _outputClasses,
        _outputScores,
        _numDetections,
      );
    } catch (e) {
      debugPrint('[ObjectDetectionService] detect error: $e');
      return const <DetectionResult>[];
    } finally {
      _isProcessing = false;
    }
  }

  Object _createInputTensor(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        inputHeight,
        (y) => List.generate(inputWidth, (x) {
          final pixel = image.getPixel(x, y);
          final red = img.getRed(pixel).toDouble();
          final green = img.getGreen(pixel).toDouble();
          final blue = img.getBlue(pixel).toDouble();

          if (inputType == 1) {
            // TfLiteType.uint8
            return [red.toInt(), green.toInt(), blue.toInt()];
          }
          return [red / 255.0, green / 255.0, blue / 255.0];
        }),
      ),
    );
  }

  List<DetectionResult> _postProcessDetections(
    List<List<List<double>>> locations,
    List<List<double>> classes,
    List<List<double>> scores,
    List<double> numDetections,
  ) {
    final count = min(10, numDetections[0].round());
    final results = <DetectionResult>[];

    for (var i = 0; i < count; i++) {
      final score = scores[0][i];
      if (score < confidenceThreshold) continue;

      final classIndex = classes[0][i].round();
      final label = classIndex >= 0 && classIndex < _labels.length
          ? _labels[classIndex]
          : 'Unknown';

      final top = locations[0][i][0];
      final left = locations[0][i][1];
      final bottom = locations[0][i][2];
      final right = locations[0][i][3];

      final rect = Rect.fromLTRB(
        left.clamp(0.0, 1.0),
        top.clamp(0.0, 1.0),
        right.clamp(0.0, 1.0),
        bottom.clamp(0.0, 1.0),
      );

      results.add(DetectionResult(label: label, confidence: score, rect: rect));
    }

    return results;
  }
}

/// Lightweight wrapper containing pixel data that can be sent to an isolate.
class DetectionFrame {
  const DetectionFrame({
    required this.width,
    required this.height,
    required this.formatGroup,
    required this.planes,
  });

  final int width;
  final int height;
  final int formatGroup;
  final List<DetectionPlane> planes;
}

class DetectionPlane {
  const DetectionPlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

// ---------------------------------------------------------------------------
// Top-level isolate functions (must be top-level or static for compute()).
// ---------------------------------------------------------------------------

/// Dispatches to the correct format converter based on [DetectionFrame.formatGroup].
///
/// Supports:
/// - [ImageFormatGroup.yuv420] — standard Android YUV420 (most flagships)
/// - [ImageFormatGroup.nv21]   — Android NV21 (common on mid-range devices)
/// - [ImageFormatGroup.bgra8888] — iOS and desktop
img.Image _convertDetectionFrame(DetectionFrame frame) {
  if (frame.formatGroup == ImageFormatGroup.yuv420.index) {
    return _convertYUV420Frame(frame);
  }
  if (frame.formatGroup == ImageFormatGroup.nv21.index) {
    return _convertNV21Frame(frame);
  }
  if (frame.formatGroup == ImageFormatGroup.bgra8888.index) {
    return _convertBGRA8888Frame(frame);
  }
  // Log and return a blank frame rather than crashing the isolate.
  debugPrint(
    '[ObjectDetectionService] Unsupported image format index: ${frame.formatGroup}. '
    'Returning blank frame.',
  );
  return img.Image(frame.width, frame.height);
}

/// Converts YUV420 (4:2:0 planar) camera frame to RGB.
///
/// Used by most flagship Android devices and iOS in yuv420 mode.
img.Image _convertYUV420Frame(DetectionFrame frame) {
  final width = frame.width;
  final height = frame.height;
  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];

  // image v3: use positional constructor
  final image = img.Image(width, height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

      final yValue = yPlane.bytes[yIndex];
      final uValue = uPlane.bytes[uvIndex];
      final vValue = vPlane.bytes[uvIndex];

      final yScaled = yValue.toInt();
      final uScaled = uValue.toInt() - 128;
      final vScaled = vValue.toInt() - 128;

      final r = (yScaled + 1.402 * vScaled).clamp(0, 255).toInt();
      final g = (yScaled - 0.34414 * uScaled - 0.71414 * vScaled)
          .clamp(0, 255)
          .toInt();
      final b = (yScaled + 1.772 * uScaled).clamp(0, 255).toInt();

      // image v3: explicit alpha argument
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // image v3: named angle parameter
  return img.copyRotate(image, angle: 90);
}

/// Converts NV21 (semi-planar YVU) camera frame to RGB.
///
/// NV21 is the default format on many mid-range Android devices. It uses a
/// single Y plane and an interleaved V,U plane (reversed vs NV12).
img.Image _convertNV21Frame(DetectionFrame frame) {
  final width = frame.width;
  final height = frame.height;
  final yPlane = frame.planes[0];
  // NV21: second plane interleaves V then U bytes
  final vuPlane = frame.planes[1];

  final image = img.Image(width, height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIdx = y * yPlane.bytesPerRow + x;
      // Each 2x2 block of pixels shares one UV pair
      final uvIdx = (y ~/ 2) * vuPlane.bytesPerRow + (x ~/ 2) * 2;

      final yS = yPlane.bytes[yIdx];
      // NV21 order: V first, then U
      final vS = vuPlane.bytes[uvIdx] - 128;
      final uS = vuPlane.bytes[uvIdx + 1] - 128;

      final r = (yS + 1.402 * vS).clamp(0, 255).toInt();
      final g = (yS - 0.34414 * uS - 0.71414 * vS).clamp(0, 255).toInt();
      final b = (yS + 1.772 * uS).clamp(0, 255).toInt();

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return img.copyRotate(image, angle: 90);
}

/// Converts BGRA8888 camera frame to RGB.
///
/// Used on iOS devices and macOS/Windows desktop via the camera plugin.
img.Image _convertBGRA8888Frame(DetectionFrame frame) {
  final width = frame.width;
  final height = frame.height;
  final plane = frame.planes[0];
  final bytesPerRow = plane.bytesPerRow;
  final bytes = plane.bytes;

  final image = img.Image(width, height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixelOffset = y * bytesPerRow + x * 4;
      final b = bytes[pixelOffset];
      final g = bytes[pixelOffset + 1];
      final r = bytes[pixelOffset + 2];
      // pixelOffset + 3 is alpha — unused

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // BGRA from iOS is already in portrait orientation — no rotation needed.
  return image;
}
