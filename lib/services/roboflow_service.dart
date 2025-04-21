// lib/services/roboflow_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

class RoboflowService {
  static const String apiKey = 'qjzJPMkESOkRCyBHsKyo'; // Your API key
  static const String modelId = 'beetleai_v2/1'; // Your model ID

  Future<List<BeetleDetection>> detectBeetles(File imageFile) async {
    try {
      final Uri uri = Uri.parse(
          'https://detect.roboflow.com/$modelId?api_key=$apiKey');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      // Process predictions
      if (jsonData['predictions'] != null) {
        List<BeetleDetection> detections = (jsonData['predictions'] as List)
            .map((pred) => BeetleDetection.fromJson(pred))
            .toList();
        return detections;
      }
      
      return [];
    } catch (e) {
      print('Error detecting beetles: $e');
      return [];
    }
  }
}
