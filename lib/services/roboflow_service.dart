import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/beetle_detection.dart';

class RoboflowService {
  static const String apiKey = 'qjzJPMkESOkRCyBHsKyo'; // Your API key 
  static const String modelId = 'beetleai_v2/1'; // Your model ID (from screenshots)
  
  // Method to detect beetles in an image
  Future<List<BeetleDetection>> detectBeetles(File imageFile) async {
    try {
      print("Making API call to Roboflow for beetle detection...");
      
      // Use confidence threshold of 0.09 as shown in your screenshot
      final Uri uri = Uri.parse(
        'https://detect.roboflow.com/$modelId?api_key=$apiKey&confidence=0.09'
      );
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
      ));

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      print("Roboflow API response: $responseData");
      
      // Parse JSON response
      final jsonData = json.decode(responseData);
        
      // Initialize empty predictions list
      List<dynamic> predictions = [];
        
      // Check multiple possible response formats
      if (jsonData.containsKey('predictions')) {
        predictions = jsonData['predictions'] as List;
        print("Found ${predictions.length} beetles in predictions array");
      } 
      else if (jsonData.containsKey('beetle_count')) {
        final beetleCount = int.tryParse(jsonData['beetle_count'].toString()) ?? 0;
        print("Found beetle_count: $beetleCount");
          
        // Generate placeholder detections based on count
        return List.generate(
          beetleCount, 
          (i) => BeetleDetection(
            x: 0.5, y: 0.5, width: 0.1, height: 0.1,
            confidence: 0.9, className: 'beetle'
          )
        );
      }
      else if (jsonData.containsKey('count_objects')) {
        final count = int.tryParse(jsonData['count_objects'].toString()) ?? 0;
        print("Found count_objects: $count");
          
        return List.generate(
          count, 
          (i) => BeetleDetection(
            x: 0.5, y: 0.5, width: 0.1, height: 0.1,
            confidence: 0.9, className: 'beetle'
          )
        );
      }
        
      // Map predictions to BeetleDetection objects
      if (predictions.isNotEmpty) {
        print("Converting ${predictions.length} predictions to BeetleDetection objects");
        return predictions.map((pred) => BeetleDetection.fromJson(pred)).toList();
      }
        
      // Return empty list as fallback (ensures non-null return)
      return [];
    } catch (e) {
      print("Error detecting beetles: $e");
      // Return empty list instead of null (ensures non-null return)
      return [];
    }
  }

  // Method to upload an image with correction for active learning
  Future<bool> uploadWithCorrection(File imageFile, int correctCount) async {
    try {
      print("Uploading image with correction: count=$correctCount");
      
      final Uri uri = Uri.parse(
        'https://api.roboflow.com/dataset/beetleai_v2/upload?api_key=$apiKey'
      );
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add metadata with improved tagging
      request.fields['name'] = 'beetle_count${correctCount}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.fields['split'] = 'train';
      request.fields['batch'] = 'mobile_app_corrections_${DateTime.now().toString().substring(0,10)}';
      request.fields['tags'] = json.encode([
        'active_learning', 
        'correct_count_$correctCount',
        'manually_verified',
        'mobile_app_upload'
      ]);
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
      ));
      
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Upload response: $responseBody");
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error uploading correction: $e");
      return false; // Return false on error (ensures non-null return)
    }
  }
  
  // Method to upload an image to dataset without correction
  Future<bool> uploadToDataset(File imageFile, List<String> tags) async {
    try {
      print("Uploading image to dataset with tags: $tags");
      
      // Construct the upload URL with your API key
      final Uri uri = Uri.parse(
        'https://api.roboflow.com/dataset/beetleai_v2/upload?api_key=$apiKey'
      );
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add metadata with more descriptive file naming
      request.fields['name'] = 'beetle_${tags.join("_")}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.fields['split'] = 'train';
      request.fields['batch'] = 'mobile_app_uploads_${DateTime.now().toString().substring(0,10)}';
      
      // Ensure tags includes required identification info
      if (!tags.contains('beetle_image')) {
        tags.add('beetle_image');
      }
      request.fields['tags'] = json.encode(tags);
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
      ));
      
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Upload response: $responseBody");
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error uploading to dataset: $e");
      return false; // Return false on error (ensures non-null return)
    }
  }
}
