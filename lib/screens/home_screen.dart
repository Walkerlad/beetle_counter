// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/roboflow_service.dart';
import 'result_screen.dart';
import 'live_detection_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RoboflowService _roboflowService = RoboflowService();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      setState(() {
        _isProcessing = true;
      });
      
      try {
        final beetles = await _roboflowService.detectBeetles(File(image.path));
        
        // Navigate to results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imagePath: image.path,
              beetleDetections: beetles,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting beetles: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beetle Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/beetle_icon.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              'Detect and Count Beetles',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            if (_isProcessing)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take a Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: Icon(Icons.photo_library),
                    label: Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.videocam),
                    label: Text('Live Detection'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LiveDetectionScreen()),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
