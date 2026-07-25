import 'dart:async';
import 'dart:typed_data';

import '../features/detection/detection_result.dart';

/// Stubbed object detection implementation for web platforms.
///
/// This avoids importing dart:ffi and package:tflite_flutter on platforms
/// where those packages are not supported.
class ObjectDetectionService {
  ObjectDetectionService._();

  static final ObjectDetectionService instance = ObjectDetectionService._();

  bool _isLoaded = false;
  bool _isProcessing = false;

  bool get isLoaded => _isLoaded;
  String? lastError;

  Future<void> initialize() async {
    _isLoaded = true;
    lastError = null;
  }

  void dispose() {
    _isLoaded = false;
    _isProcessing = false;
  }

  Future<List<DetectionResult>> detect(DetectionFrame frame) async {
    if (!_isLoaded || _isProcessing) return const <DetectionResult>[];

    _isProcessing = true;
    try {
      // For web, return no detections until a supported inference path is added.
      return const <DetectionResult>[];
    } finally {
      _isProcessing = false;
    }
  }
}

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
