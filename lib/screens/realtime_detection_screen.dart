// lib/screens/realtime_detection_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/roboflow_service.dart';
import '../models/beetle_detection.dart';

class RealtimeDetectionScreen extends StatefulWidget {
  @override
  _RealtimeDetectionScreenState createState() => _RealtimeDetectionScreenState();
}

class _RealtimeDetectionScreenState extends State<RealtimeDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDetecting = false;
  List<BeetleDetection> _detections = [];
  int _beetleCount = 0;
  final RoboflowService _roboflowService = RoboflowService();
  Timer? _detectionTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;
    
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      // Start periodic detection
      _detectionTimer = Timer.periodic(Duration(seconds: 2), (_) {
        _detectBeetlesInLiveView();
      });
    }
  }
  
  Future<void> _detectBeetlesInLiveView() async {
    if (_isDetecting || !_isInitialized) return;
    
    setState(() {
      _isDetecting = true;
    });
    
    try {
      // Capture frame
      final XFile image = await _cameraController!.takePicture();
      
      // Process with Roboflow
      final detections = await _roboflowService.detectBeetles(File(image.path));
      
      // Update UI
      if (mounted) {
        setState(() {
          _detections = detections;
          _beetleCount = detections.length;
          _isDetecting = false;
        });
      }
      
      // Delete the temporary image
      try {
        await File(image.path).delete();
      } catch (e) {
        // Ignore deletion errors
      }
    } catch (e) {
      print('Error in realtime detection: $e');
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Beetle Detection'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraController!),
          
          // Overlay for beetle detections
          CustomPaint(
            painter: BeetleDetectionPainter(
              detections: _detections,
              previewSize: _cameraController!.value.previewSize!,
              screenSize: MediaQuery.of(context).size,
            ),
          ),
          
          // Beetle count indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Beetles: $_beetleCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Processing indicator
          if (_isDetecting)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capture and save the current frame
          final XFile image = await _cameraController!.takePicture();
          
          // Navigate to result screen for corrections
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                imagePath: image.path,
                beetleDetections: _detections,
              ),
            ),
          );
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}

// Custom painter for drawing detection boxes
class BeetleDetectionPainter extends CustomPainter {
  final List<BeetleDetection> detections;
  final Size previewSize;
  final Size screenSize;
  
  BeetleDetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.green;
      
    for (var detection in detections) {
      // Convert normalized coordinates to screen coordinates
      final rect = Rect.fromLTWH(
        (detection.x - detection.width / 2) * screenSize.width,
        (detection.y - detection.height / 2) * screenSize.height,
        detection.width * screenSize.width,
        detection.height * screenSize.height,
      );
      
      canvas.drawRect(rect, paint);
    }
  }
  
  @override
  bool shouldRepaint(BeetleDetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
