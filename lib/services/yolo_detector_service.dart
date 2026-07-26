import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../features/detection/detection_result.dart';

/// YoloDetectorService manages TFLite model inference (YOLOv8 / MobileNet SSD),
/// downsamples camera frames in a background isolate, parses tensor outputs,
/// applies NMS filtering, and estimates physical distance via pinhole optics.
class YoloDetectorService {
  YoloDetectorService._();

  static final YoloDetectorService instance = YoloDetectorService._();

  static const String modelAsset = 'assets/models/ssd_mobilenet.tflite';
  static const String labelsAsset = 'assets/models/ssd_mobilenet_labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool _isLoaded = false;
  bool _isInitializing = false;
  bool _isProcessing = false;

  int _inputWidth = 300;
  int _inputHeight = 300;
  String _inputTypeString = '';

  late List<List<List<double>>> _outputLocations;
  late List<List<double>> _outputClasses;
  late List<List<double>> _outputScores;
  late List<double> _numDetections;

  double confidenceThreshold = 0.45;
  double iouThreshold = 0.45;

  bool get isLoaded => _isLoaded;
  bool get isProcessing => _isProcessing;

  /// Known real-world reference heights (in meters) for COCO object categories
  static const Map<String, double> objectReferenceHeights = {
    'person': 1.70,
    'bicycle': 1.00,
    'car': 1.50,
    'motorcycle': 1.10,
    'bus': 3.00,
    'truck': 2.20,
    'boat': 1.80,
    'traffic light': 1.00,
    'fire hydrant': 0.70,
    'stop sign': 0.75,
    'bench': 0.85,
    'bird': 0.20,
    'cat': 0.30,
    'dog': 0.55,
    'backpack': 0.45,
    'umbrella': 0.85,
    'handbag': 0.35,
    'tie': 0.40,
    'suitcase': 0.60,
    'bottle': 0.25,
    'wine glass': 0.20,
    'cup': 0.12,
    'fork': 0.18,
    'knife': 0.20,
    'spoon': 0.15,
    'bowl': 0.15,
    'banana': 0.18,
    'apple': 0.08,
    'sandwich': 0.10,
    'orange': 0.08,
    'broccoli': 0.15,
    'carrot': 0.15,
    'hot dog': 0.12,
    'pizza': 0.30,
    'donut': 0.10,
    'cake': 0.20,
    'chair': 0.85,
    'couch': 0.80,
    'potted plant': 0.60,
    'bed': 0.65,
    'dining table': 0.75,
    'toilet': 0.70,
    'tv': 0.55,
    'laptop': 0.25,
    'mouse': 0.06,
    'remote': 0.18,
    'keyboard': 0.15,
    'cell phone': 0.15,
    'microwave': 0.35,
    'oven': 0.85,
    'toaster': 0.20,
    'sink': 0.40,
    'refrigerator': 1.75,
    'book': 0.24,
    'clock': 0.30,
    'vase': 0.30,
    'scissors': 0.18,
    'teddy bear': 0.35,
    'hair drier': 0.22,
    'toothbrush': 0.18,
    'shoe': 0.12,
  };

  /// Loads the TFLite model and labels asset file.
  Future<void> initialize() async {
    if (_isLoaded || _isInitializing) return;
    _isInitializing = true;

    try {
      // 1. Load label names
      try {
        final labelData = await rootBundle.loadString(labelsAsset);
        _labels = labelData
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        debugPrint('[YoloDetectorService] Loaded ${_labels.length} labels.');
      } catch (e) {
        debugPrint('[YoloDetectorService] Labels load error: $e');
        _labels = [];
      }

      // 2. Validate model asset size
      try {
        final modelData = await rootBundle.load(modelAsset);
        final bytes = modelData.lengthInBytes;
        debugPrint('[YoloDetectorService] Model asset size: $bytes bytes.');
        if (bytes < 500000) {
          debugPrint('[YoloDetectorService] Model binary placeholder detected.');
          _isLoaded = false;
          return;
        }
      } catch (e) {
        debugPrint('[YoloDetectorService] Model read error: $e');
      }

      // 3. Load TFLite Interpreter
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelAsset, options: options);

      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      _inputHeight = inputShape.length > 1 ? inputShape[1] : 300;
      _inputWidth = inputShape.length > 2 ? inputShape[2] : 300;
      _inputTypeString = inputTensor.type.toString().toLowerCase();

      // Diagnostic Log 1: Input & Output Tensors
      debugPrint('[YOLO Model Loaded Successfully]');
      debugPrint('   -> Input Tensor Shape: $inputShape | Type: ${inputTensor.type}');
      final outputTensors = _interpreter!.getOutputTensors();
      debugPrint('   -> Model Output Tensors Count: ${outputTensors.length}');
      for (var i = 0; i < outputTensors.length; i++) {
        debugPrint('      Output [$i]: Shape=${outputTensors[i].shape} | Type=${outputTensors[i].type}');
      }

      const int maxDetections = 10;
      _outputLocations = List.generate(
        1,
        (_) => List.generate(maxDetections, (_) => List.filled(4, 0.0)),
      );
      _outputClasses = List.generate(1, (_) => List.filled(maxDetections, 0.0));
      _outputScores = List.generate(1, (_) => List.filled(maxDetections, 0.0));
      _numDetections = List.filled(1, 0.0);

      // Temporarily lower confidence threshold to 0.15 to rule out strict filtering
      confidenceThreshold = 0.15;
      iouThreshold = 0.30;

      _isLoaded = true;
    } catch (e, stackTrace) {
      debugPrint('[YoloDetectorService] Model Load Error: $e\n$stackTrace');
      _isLoaded = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Processes live camera frame asynchronously with full diagnostics.
  Future<List<DetectionResult>> detect(CameraImage image) async {
    if (!_isLoaded || _interpreter == null || _isProcessing) {
      return const <DetectionResult>[];
    }

    _isProcessing = true;
    try {
      // Diagnostic Log 2: Camera Image Format & Specs
      if (kDebugMode) {
        debugPrint(
          '[Camera Image Format] ${image.format.group} | Specs: ${image.width}x${image.height} | Planes: ${image.planes.length}',
        );
      }

      final frame = DetectionFrame(
        width: image.width,
        height: image.height,
        formatGroup: image.format.group.index,
        planes: image.planes
            .map(
              (p) => DetectionPlane(
                bytes: p.bytes,
                bytesPerRow: p.bytesPerRow,
                bytesPerPixel: p.bytesPerPixel ?? 1,
              ),
            )
            .toList(),
      );

      final resized = await compute<ConvertParams, img.Image>(
        _convertAndResizeFrame,
        ConvertParams(frame: frame, targetW: _inputWidth, targetH: _inputHeight),
      );

      final input = _createInputTensor(resized);

      final outputs = <int, Object>{
        0: _outputLocations,
        1: _outputClasses,
        2: _outputScores,
        3: _numDetections,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      // Diagnostic Log 3: Inspect Raw Output Tensor Values
      if (kDebugMode) {
        debugPrint(
          '[Raw Output Scores] First 10 scores: ${_outputScores[0].take(10).map((s) => s.toStringAsFixed(3)).toList()}',
        );
        debugPrint(
          '[Raw Output Classes] First 10 class IDs: ${_outputClasses[0].take(10).map((c) => c.round()).toList()}',
        );
        debugPrint(
          '[Raw Output Count] Valid count: ${_numDetections[0]}',
        );
      }

      final rawResults = _postProcessDetections(
        _outputLocations,
        _outputClasses,
        _outputScores,
        _numDetections,
      );

      if (rawResults.isEmpty) {
        debugPrint('[YOLO Diagnostic] No detections this frame (all candidates below threshold $confidenceThreshold)');
      } else {
        debugPrint('[YOLO Diagnostic] Found ${rawResults.length} detections this frame:');
        for (final r in rawResults) {
          debugPrint(
            '   -> "${r.label}" (${(r.confidence * 100).toStringAsFixed(1)}%) | rect=${r.rect}',
          );
        }
      }

      return rawResults;
    } catch (e, stackTrace) {
      debugPrint('[YoloDetectorService] Exception during inference: $e\n$stackTrace');
      return const <DetectionResult>[];
    } finally {
      _isProcessing = false;
    }
  }

  Object _createInputTensor(img.Image image) {
    final isFloat = _inputTypeString.contains('float');

    return List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (y) => List.generate(_inputWidth, (x) {
          final pixel = image.getPixel(x, y);
          final r = img.getRed(pixel);
          final g = img.getGreen(pixel);
          final b = img.getBlue(pixel);
          if (isFloat) {
            return [r / 255.0, g / 255.0, b / 255.0];
          }
          return [r.toInt(), g.toInt(), b.toInt()];
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
    final rawResults = <DetectionResult>[];

    for (var i = 0; i < count; i++) {
      final score = scores[0][i];
      if (score < confidenceThreshold) continue;

      final classIndex = classes[0][i].round();
      if (classIndex < 0 || classIndex >= _labels.length) continue;

      String label = _labels[classIndex];
      if (label == '???' || label.trim().isEmpty) continue;

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

      final area = rect.width * rect.height;
      if (area < 0.002) continue;

      // Anti-misclassification safeguard: Laptop screen on desk mapped correctly
      if ((label == 'tv' || label == 'remote') && rect.bottom > 0.35 && rect.width > 0.20) {
        label = 'laptop';
      }

      rawResults.add(
        DetectionResult(label: label, confidence: score, rect: rect),
      );
    }

    return _applyNMS(rawResults, iouThreshold);
  }

  List<DetectionResult> _applyNMS(
    List<DetectionResult> detections,
    double threshold,
  ) {
    if (detections.length <= 1) return detections;

    final sorted = List<DetectionResult>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <DetectionResult>[];
    final active = List<bool>.filled(sorted.length, true);

    for (var i = 0; i < sorted.length; i++) {
      if (!active[i]) continue;
      final current = sorted[i];
      selected.add(current);

      for (var j = i + 1; j < sorted.length; j++) {
        if (!active[j]) continue;
        final iou = _calculateIoU(current.rect, sorted[j].rect);
        if (iou >= threshold) {
          active[j] = false;
        }
      }
    }

    return selected;
  }

  double _calculateIoU(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.width <= 0 || intersection.height <= 0) return 0.0;
    final areaInt = intersection.width * intersection.height;
    final unionArea = (a.width * a.height) + (b.width * b.height) - areaInt;
    if (unionArea <= 0) return 0.0;
    return areaInt / unionArea;
  }

  /// Calculates dynamic pinhole physical distance in meters given object label and normalized bounding box rect.
  double estimatePinholeDistance(String label, Rect rect, Size viewportSize) {
    final lowerLabel = label.toLowerCase().trim();
    final realHeight = objectReferenceHeights[lowerLabel] ?? 0.50;

    final bboxHeightPx = rect.height * viewportSize.height;
    if (bboxHeightPx <= 1.0) return 8.0;

    // Approximate focal length in pixels for smartphone camera (~60° VFOV)
    final focalLengthPx = viewportSize.height * 1.15;
    final distance = (realHeight * focalLengthPx) / bboxHeightPx;

    return distance.clamp(0.3, 10.0);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    _isProcessing = false;
  }
}

class ConvertParams {
  const ConvertParams({
    required this.frame,
    required this.targetW,
    required this.targetH,
  });

  final DetectionFrame frame;
  final int targetW;
  final int targetH;
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

img.Image _convertAndResizeFrame(ConvertParams params) {
  final frame = params.frame;
  final targetW = params.targetW;
  final targetH = params.targetH;

  if (frame.planes.isEmpty) return img.Image(targetW, targetH);

  if (frame.formatGroup == ImageFormatGroup.yuv420.index && frame.planes.length >= 3) {
    return _convertAndResizeYUV420(frame, targetW, targetH);
  }

  return img.Image(targetW, targetH);
}

img.Image _convertAndResizeYUV420(DetectionFrame frame, int targetW, int targetH) {
  final srcW = frame.width;
  final srcH = frame.height;
  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];

  final image = img.Image(targetW, targetH);
  final uStride = uPlane.bytesPerPixel > 0 ? uPlane.bytesPerPixel : 1;
  final vStride = vPlane.bytesPerPixel > 0 ? vPlane.bytesPerPixel : 1;

  final maxTargetY = targetH - 1;
  final maxTargetX = targetW - 1;
  final maxSrcW = srcW - 1;
  final maxSrcH = srcH - 1;

  for (var targetY = 0; targetY < targetH; targetY++) {
    final srcY = ((targetY / maxTargetY) * maxSrcH).toInt().clamp(0, maxSrcH);

    for (var targetX = 0; targetX < targetW; targetX++) {
      final srcX = ((targetX / maxTargetX) * maxSrcW).toInt().clamp(0, maxSrcW);

      final yIndex = srcY * yPlane.bytesPerRow + srcX;
      final uvX = srcX ~/ 2;
      final uvY = srcY ~/ 2;

      final uIndex = uvY * uPlane.bytesPerRow + uvX * uStride;
      final vIndex = uvY * vPlane.bytesPerRow + uvX * vStride;

      if (yIndex < yPlane.bytes.length &&
          uIndex < uPlane.bytes.length &&
          vIndex < vPlane.bytes.length) {
        final yVal = yPlane.bytes[yIndex].toInt();
        final uVal = uPlane.bytes[uIndex].toInt() - 128;
        final vVal = vPlane.bytes[vIndex].toInt() - 128;

        final r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
        final g = (yVal - 0.34414 * uVal - 0.71414 * vVal).clamp(0, 255).toInt();
        final b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

        image.setPixelRgba(targetX, targetY, r, g, b, 255);
      }
    }
  }

  return image;
}
