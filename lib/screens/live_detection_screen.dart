// lib/screens/live_detection_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/roboflow_service.dart';
import '../models/beetle_detection.dart';
import 'result_screen.dart';

class LiveDetectionScreen extends StatefulWidget {
  @override
  _LiveDetectionScreenState createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDetecting = false;
  List<BeetleDetection> _detections = [];
  int _beetleCount = 0;
  Timer? _detectionTimer;
  final RoboflowService _roboflowService = RoboflowService();
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return;
      
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Process a frame every 2 seconds
        _detectionTimer = Timer.periodic(Duration(seconds: 2), (_) {
          _processCurrentFrame();
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  Future<void> _processCurrentFrame() async {
    if (_isDetecting || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    setState(() => _isDetecting = true);
    
    try {
      // Capture frame
      final image = await _controller!.takePicture();
      
      // Process with Roboflow API
      final detections = await _roboflowService.detectBeetles(File(image.path));
      
      // Update UI with results
      if (mounted) {
        setState(() {
          _detections = detections;
          _beetleCount = detections.length;
          _isDetecting = false;
        });
      }
      
      // Clean up temporary file
      try {
        await File(image.path).delete();
      } catch (e) {
        // Ignore deletion errors
      }
    } catch (e) {
      print('Error in frame processing: $e');
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Live Beetle Detection')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Live Beetle Detection')),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),
          
          // Beetle count indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Beetles Detected: $_beetleCount',
                  style: TextStyle(color: Colors.white, fontSize: 18),
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          
          // Detection boxes overlay
          CustomPaint(
            painter: BeetleDetectionPainter(
              detections: _detections,
              screenSize: MediaQuery.of(context).size,
            ),
            size: Size.infinite,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _processCurrentFrame,
        tooltip: 'Detect beetles',
        child: Icon(Icons.camera),
      ),
    );
  }
}

class BeetleDetectionPainter extends CustomPainter {
  final List<BeetleDetection> detections;
  final Size screenSize;
  
  BeetleDetectionPainter({
    required this.detections,
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
      
      // Draw confidence score
      final textSpan = TextSpan(
        text: '${(detection.confidence * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white,
          backgroundColor: Colors.black54,
          fontSize: 12,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft);
    }
  }
  
  @override
  bool shouldRepaint(BeetleDetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
