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

  bool _isLoaded = false;
  bool _isProcessing = false;

  /// Image dimensions expected by the model.
  late final int inputWidth;
  late final int inputHeight;

  /// Minimum detection confidence threshold.
  double confidenceThreshold = 0.50;

  String? lastError;

  bool get isLoaded => _isLoaded;

  /// Loads the model and label file from assets.
  late final TfLiteType inputType;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset(modelAsset);
      final labelData = await rootBundle.loadString(labelsAsset);
      _labels = labelData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final inputTensor = _interpreter!.getInputTensor(0);
      final shape = inputTensor.shape;
      inputHeight = shape[1];
      inputWidth = shape[2];
      inputType = inputTensor.type;

      _isLoaded = true;
      lastError = null;
    } catch (e) {
      lastError = 'AI model failed to load.';
      debugPrint('[ObjectDetectionService] initialize error: $e');
      _isLoaded = false;
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

      final outputLocations = List.generate(
        1,
        (_) => List.generate(10, (_) => List.filled(4, 0.0)),
      );
      final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
      final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
      final numDetections = List.filled(1, 0.0);

      final outputs = <int, Object>{
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      return _postProcessDetections(
        outputLocations,
        outputClasses,
        outputScores,
        numDetections,
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

          if (inputType == TfLiteType.uint8) {
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

img.Image _convertDetectionFrame(DetectionFrame frame) {
  if (frame.formatGroup == ImageFormatGroup.yuv420.index) {
    return _convertYUV420Frame(frame);
  }

  throw StateError('Unsupported image format: ${frame.formatGroup}');
}

img.Image _convertYUV420Frame(DetectionFrame frame) {
  final width = frame.width;
  final height = frame.height;
  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];
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

      var r = yScaled + 1.402 * vScaled;
      var g = yScaled - 0.34414 * uScaled - 0.71414 * vScaled;
      var b = yScaled + 1.772 * uScaled;

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt());
    }
  }

  return img.copyRotate(image, 90);
}
