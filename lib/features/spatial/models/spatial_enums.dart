/// Directional position of detected objects relative to the camera field of view.
enum ObjectDirection {
  left,
  center,
  right,
}

/// Estimated distance tier derived from bounding box dimensions.
enum ObjectDistance {
  near,
  medium,
  far,
}

/// Evaluated risk level for navigation safety.
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}
