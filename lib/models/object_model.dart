// Model representing a detected object for future AI integrations.
class ObjectModel {
  const ObjectModel({required this.label, required this.confidence});

  final String label;
  final double confidence;
}
