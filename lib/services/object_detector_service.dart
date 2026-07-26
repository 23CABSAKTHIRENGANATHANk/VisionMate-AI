
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Service managing Google ML Kit Object Detection & Tracking.
/// Runs in streaming mode with async frame skipping to prevent UI lag.
class ObjectDetectorService {
  ObjectDetectorService._();

  static final ObjectDetectorService instance = ObjectDetectorService._();

  ObjectDetector? _objectDetector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  /// Initializes the ML Kit ObjectDetector in streaming mode with classification enabled.
  void initialize() {
    if (_isInitialized) return;

    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      multipleObjects: true,
      classifyObjects: true,
    );

    _objectDetector = ObjectDetector(options: options);
    _isInitialized = true;
    debugPrint('[ObjectDetectorService] Google ML Kit Object Detector Initialized.');
  }

  /// Processes a live camera frame. Skips execution if previous frame is still processing.
  Future<List<DetectedObject>> processImage({
    required CameraImage image,
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
  }) async {
    if (!_isInitialized || _objectDetector == null || _isProcessing) {
      return const <DetectedObject>[];
    }

    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(
        image: image,
        sensorOrientation: sensorOrientation,
        deviceOrientation: deviceOrientation,
      );

      if (inputImage == null) return const <DetectedObject>[];

      final objects = await _objectDetector!.processImage(inputImage);
      final filtered = _applyNMS(objects, 0.40);

      if (kDebugMode && filtered.isNotEmpty) {
        debugPrint('[MLKit Dynamic Frame] ${filtered.length} object(s) detected:');
        for (final obj in filtered) {
          final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Obstacle';
          final conf = obj.labels.isNotEmpty ? obj.labels.first.confidence : 0.0;
          debugPrint(
            '   -> ID:#${obj.trackingId ?? 0} "$label" (${(conf * 100).toStringAsFixed(1)}%) | rect=${obj.boundingBox}',
          );
        }
      }

      return filtered;
    } catch (e) {
      debugPrint('[ObjectDetectorService] Detection error: $e');
      return const <DetectedObject>[];
    } finally {
      _isProcessing = false;
    }
  }

  /// Converts Flutter [CameraImage] to ML Kit [InputImage].
  InputImage? _inputImageFromCameraImage({
    required CameraImage image,
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
  }) {
    final cameraRotation = _getRotation(sensorOrientation, deviceOrientation);
    if (cameraRotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: cameraRotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation? _getRotation(
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) {
    final rotationCompensation = _getDeviceRotationCompensation(deviceOrientation);
    final rotation = (sensorOrientation - rotationCompensation + 360) % 360;

    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  int _getDeviceRotationCompensation(DeviceOrientation deviceOrientation) {
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90;
      case DeviceOrientation.portraitDown:
        return 180;
      case DeviceOrientation.landscapeRight:
        return 270;
    }
  }

  /// NMS-style filtering: merges or filters duplicate boxes exceeding 40% IoU.
  List<DetectedObject> _applyNMS(List<DetectedObject> objects, double iouThreshold) {
    if (objects.length <= 1) return objects;

    final sorted = List<DetectedObject>.from(objects)
      ..sort((a, b) {
        final confA = a.labels.isNotEmpty ? a.labels.first.confidence : 0.0;
        final confB = b.labels.isNotEmpty ? b.labels.first.confidence : 0.0;
        return confB.compareTo(confA);
      });

    final selected = <DetectedObject>[];
    final active = List<bool>.filled(sorted.length, true);

    for (var i = 0; i < sorted.length; i++) {
      if (!active[i]) continue;
      final current = sorted[i];
      selected.add(current);

      for (var j = i + 1; j < sorted.length; j++) {
        if (!active[j]) continue;
        final iou = _calculateIoU(current.boundingBox, sorted[j].boundingBox);
        if (iou >= iouThreshold) {
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

  void dispose() {
    _objectDetector?.close();
    _objectDetector = null;
    _isInitialized = false;
  }
}
