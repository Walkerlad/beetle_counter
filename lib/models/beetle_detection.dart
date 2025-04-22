// lib/models/beetle_detection.dart
class BeetleDetection {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final String className;

  BeetleDetection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.className,
  });

  factory BeetleDetection.fromJson(Map<String, dynamic> json) {
    return BeetleDetection(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      width: json['width']?.toDouble() ?? 0.0,
      height: json['height']?.toDouble() ?? 0.0,
      confidence: json['confidence']?.toDouble() ?? 0.0,
      className: json['class'] ?? 'beetle',
    );
  }
}
